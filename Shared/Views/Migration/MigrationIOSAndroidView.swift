import SwiftUI

#if os(iOS)
import LocalAuthentication
import NetworkExtension
import VisionKit

@MainActor
private final class WirelessMigrationViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case joiningNetwork
        case preparing
        case discovering
        case transferring
        case importing
        case completed
        case failed(String)

        var isWorking: Bool {
            switch self {
            case .joiningNetwork, .preparing, .discovering, .transferring, .importing: true
            default: false
            }
        }
    }

    @Published var direction: WirelessSyncDirection = .androidToIOS
    @Published var transferEverything = true
    @Published var selectedTypes = Set(MigrationRecordType.allWirelessTypes)
    @Published var phase: Phase = .idle
    @Published var isUnlocked = false
    @Published var isScannerPresented = false
    @Published var completionSummary: WirelessTransferSummary?

    private let migrationService = MyAppMigrationService()
    private let client = WirelessSyncClient()

    func unlock() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            phase = .failed(error?.localizedDescription ?? "Configura un código de desbloqueo en el dispositivo")
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Autoriza la transferencia de tus datos personales"
        ) { [weak self] success, evaluationError in
            Task { @MainActor in
                if success {
                    self?.isUnlocked = true
                    self?.phase = .idle
                } else {
                    self?.phase = .failed(evaluationError?.localizedDescription ?? "No se pudo autorizar el acceso")
                }
            }
        }
    }

    func scan() {
        guard isUnlocked else {
            unlock()
            return
        }
        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else {
            phase = .failed("La cámara no está disponible para escanear el código QR")
            return
        }
        isScannerPresented = true
    }

    func receiveScannedPayload(_ payload: String) {
        isScannerPresented = false
        Task { await performTransfer(qrPayload: payload) }
    }

    private func performTransfer(qrPayload: String) async {
        var session: WirelessSyncSession?
        do {
            let descriptor = try WirelessSessionDescriptor.parse(qrPayload: qrPayload)
            direction = descriptor.direction
            if descriptor.direction == .bidirectional {
                transferEverything = descriptor.includedTypes == nil
                if let includedTypes = descriptor.includedTypes {
                    selectedTypes = Set(includedTypes)
                }
            }
            if let network = descriptor.network {
                phase = .joiningNetwork
                try await join(network)
            }

            var outgoingExport: ExportResult?
            if descriptor.direction == .iosToAndroid || descriptor.direction == .bidirectional {
                phase = .preparing
                let includedTypes: Set<String>?
                if descriptor.direction == .bidirectional {
                    includedTypes = descriptor.includedTypes.map(Set.init)
                } else {
                    includedTypes = transferEverything ? nil : selectedTypes
                }
                outgoingExport = try await migrationService.exportAsync(
                    password: descriptor.secret,
                    includedTypes: includedTypes,
                    allowEmpty: descriptor.direction == .bidirectional
                )
            }

            phase = .discovering
            let connectedSession = try await client.connect(to: descriptor)
            session = connectedSession
            phase = .transferring

            switch descriptor.direction {
            case .iosToAndroid:
                guard let outgoingExport else {
                    throw WirelessSyncError.protocolViolation("No se pudo preparar el paquete")
                }
                try await connectedSession.send(type: .package, payload: outgoingExport.bytes)
                let result = try await connectedSession.receive()
                guard result.type == .result else {
                    throw WirelessSyncError.protocolViolation("Android no confirmó la importación")
                }
                let remoteResult = try importResult(from: result.payload)
                complete(WirelessTransferSummary(
                    direction: descriptor.direction,
                    sent: outgoingExport.countsByType.values.reduce(0, +),
                    received: 0,
                    localImport: .empty,
                    remoteImport: remoteResult
                ))

            case .androidToIOS:
                let packageFrame = try await connectedSession.receive()
                guard packageFrame.type == .package else {
                    throw WirelessSyncError.protocolViolation("Android no envió un paquete válido")
                }
                phase = .importing
                let preview = try await migrationService.preview(
                    fileBytes: packageFrame.payload,
                    password: descriptor.secret
                )
                guard preview.errors.isEmpty else {
                    throw MigrationError.validation("El paquete contiene registros inválidos")
                }
                let summary = try await migrationService.importPreview(preview, policy: .newerWins)
                let localResult = WirelessImportResult(summary: summary, message: summaryMessage(summary))
                try await connectedSession.send(type: .result, payload: try JSONEncoder().encode(localResult))
                complete(WirelessTransferSummary(
                    direction: descriptor.direction,
                    sent: 0,
                    received: preview.records.count,
                    localImport: localResult,
                    remoteImport: .empty
                ))

            case .bidirectional:
                guard let outgoingExport else {
                    throw WirelessSyncError.protocolViolation("No se pudo preparar el paquete")
                }
                let androidPackage = try await connectedSession.receive()
                guard androidPackage.type == .package else {
                    throw WirelessSyncError.protocolViolation("Android no envió un paquete válido")
                }
                phase = .importing
                let preview = try await migrationService.preview(
                    fileBytes: androidPackage.payload,
                    password: descriptor.secret
                )
                guard preview.errors.isEmpty else {
                    throw MigrationError.validation("El paquete contiene registros inválidos")
                }
                let localSummary = try await migrationService.importPreview(
                    preview,
                    policy: .newerWinsIncomingOnTie
                )
                let localResult = WirelessImportResult(
                    summary: localSummary,
                    message: summaryMessage(localSummary)
                )
                try await connectedSession.send(type: .result, payload: try JSONEncoder().encode(localResult))

                phase = .transferring
                try await connectedSession.send(type: .package, payload: outgoingExport.bytes)
                let androidResultFrame = try await connectedSession.receive()
                guard androidResultFrame.type == .result else {
                    throw WirelessSyncError.protocolViolation("Android no confirmó la sincronización")
                }
                let remoteResult = try importResult(from: androidResultFrame.payload)
                complete(WirelessTransferSummary(
                    direction: descriptor.direction,
                    sent: outgoingExport.countsByType.values.reduce(0, +),
                    received: preview.records.count,
                    localImport: localResult,
                    remoteImport: remoteResult
                ))
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
        session?.cancel()
    }

    private func join(_ network: WirelessNetworkCredentials) async throws {
        let configuration = NEHotspotConfiguration(
            ssid: network.ssid,
            passphrase: network.password,
            isWEP: false
        )
        configuration.joinOnce = true
        try await withCheckedThrowingContinuation { continuation in
            NEHotspotConfigurationManager.shared.apply(configuration) { error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == NEHotspotConfigurationErrorDomain,
                       nsError.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func importResult(from data: Data) throws -> WirelessImportResult {
        do {
            return try JSONDecoder().decode(WirelessImportResult.self, from: data)
        } catch {
            throw WirelessSyncError.protocolViolation("Respuesta de Android inválida")
        }
    }

    private func complete(_ summary: WirelessTransferSummary) {
        completionSummary = summary
        phase = .completed
    }

    private func summaryMessage(_ summary: MigrationSummary) -> String {
        "Importados: \(summary.inserted) · Actualizados: \(summary.updated) · Omitidos: \(summary.skipped) · Conflictos: \(summary.conflicts)"
    }
}

private extension MigrationRecordType {
    static let allWirelessTypes: [String] = [
        note, diary, agenda, goal, archivedGoal, personalPhrase,
        personalReflection, dayRitualArchive, calmPersonalPhrase
    ]

    static func localizedName(_ type: String) -> String {
        switch type {
        case note: L10n.exact("Notas")
        case diary: L10n.exact("Diario")
        case agenda: L10n.exact("Agenda")
        case goal: L10n.exact("Metas activas")
        case archivedGoal: L10n.exact("Metas archivadas")
        case personalPhrase: L10n.exact("Frases personales")
        case personalReflection: L10n.exact("Reflexiones personales")
        case dayRitualArchive: L10n.exact("Rituales")
        case calmPersonalPhrase: L10n.exact("Frases de Calma")
        default: type
        }
    }
}

struct MigrationIOSAndroidView: View {
    @StateObject private var viewModel = WirelessMigrationViewModel()
    @State private var isInfoPresented = false

    private let contentColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        Form {
            Section {
                Text("La transferencia es local, cifrada y no utiliza Internet. Android mostrará el código de enlace y este dispositivo lo escaneará.")
                    .foregroundStyle(.secondary)
            }

            if viewModel.isUnlocked {
                Section("Dirección") {
                    directionButton(
                        .androidToIOS,
                        title: "Recibir desde Android",
                        icon: "arrow.down.circle"
                    )
                    directionButton(
                        .iosToAndroid,
                        title: "Enviar a Android",
                        icon: "arrow.up.circle"
                    )
                    directionButton(
                        .bidirectional,
                        title: "Sincronizar ambos dispositivos",
                        icon: "arrow.triangle.2.circlepath"
                    )
                }

                if viewModel.direction != .androidToIOS {
                    Section {
                        Toggle("Transferir todo", isOn: $viewModel.transferEverything)
                        if !viewModel.transferEverything {
                            LazyVGrid(columns: contentColumns, spacing: 8) {
                                ForEach(MigrationRecordType.allWirelessTypes, id: \.self) { type in
                                    contentSelectionButton(for: type)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Contenido")
                    } footer: {
                        if viewModel.direction == .bidirectional {
                            Text("En la sincronización, Android incluirá esta selección en el enlace para aplicarla en ambos dispositivos.")
                        }
                    }
                }

                Section {
                    Button {
                        viewModel.scan()
                    } label: {
                        Label("Escanear código de Android", systemImage: "qrcode.viewfinder")
                    }
                    .disabled(
                        viewModel.phase.isWorking ||
                        (viewModel.direction != .androidToIOS && !viewModel.transferEverything && viewModel.selectedTypes.isEmpty)
                    )
                } footer: {
                    Text("Si no compartís una red Wi‑Fi, selecciona “Conexión directa” en Android.")
                }

                statusSection
            } else {
                Section("Acceso protegido") {
                    Button {
                        viewModel.unlock()
                    } label: {
                        Label("Desbloquear transferencia", systemImage: "lock.open")
                    }
                }
                statusSection
            }
        }
        .navigationTitle("Transferir datos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isInfoPresented = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Información sobre la transferencia")
            }
        }
        .sheet(isPresented: $isInfoPresented) {
            WirelessSyncInfoView()
        }
        .sheet(isPresented: $viewModel.isScannerPresented) {
            WirelessQRCodeScanner { payload in
                viewModel.receiveScannedPayload(payload)
            }
            .ignoresSafeArea()
        }
        .sheet(item: $viewModel.completionSummary) { summary in
            WirelessTransferSummaryView(summary: summary)
        }
    }

    private func directionButton(
        _ direction: WirelessSyncDirection,
        title: LocalizedStringKey,
        icon: String
    ) -> some View {
        let isSelected = viewModel.direction == direction
        return Button {
            viewModel.direction = direction
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func contentSelectionButton(for type: String) -> some View {
        let isSelected = viewModel.selectedTypes.contains(type)
        return Button {
            if isSelected {
                viewModel.selectedTypes.remove(type)
            } else {
                viewModel.selectedTypes.insert(type)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(MigrationRecordType.localizedName(type))
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.55) : Color.secondary.opacity(0.2))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MigrationRecordType.localizedName(type))
        .accessibilityValue(isSelected ? "Seleccionado" : "No seleccionado")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .joiningNetwork:
            progressSection("Uniéndose a la conexión directa…")
        case .preparing:
            progressSection("Preparando y cifrando el paquete…")
        case .discovering:
            progressSection("Localizando Android…")
        case .transferring:
            progressSection("Transfiriendo datos…")
        case .importing:
            progressSection("Validando e importando…")
        case .completed:
            Section("Transferencia completada") {
                Label("Consulta el resumen de la operación.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .failed(let message):
            Section("No se pudo completar") {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func progressSection(_ title: String) -> some View {
        Section {
            HStack(spacing: 12) {
                ProgressView()
                Text(title)
            }
        }
    }
}

private struct WirelessTransferSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let summary: WirelessTransferSummary

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)
                    VStack(spacing: 6) {
                        Text(summary.direction == .bidirectional
                             ? LocalizedStringKey("Sincronización completada")
                             : LocalizedStringKey("Transferencia completada"))
                            .font(.title2.bold())
                        Text(summary.direction == .bidirectional
                             ? LocalizedStringKey("Ambos dispositivos han aplicado las versiones más recientes.")
                             : LocalizedStringKey("La operación terminó correctamente."))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        summaryRow("Elementos enviados", value: summary.sent, icon: "arrow.up.circle")
                        Divider().padding(.leading, 44)
                        summaryRow("Elementos recibidos", value: summary.received, icon: "arrow.down.circle")
                        Divider().padding(.leading, 44)
                        summaryRow("Añadidos", value: summary.totalInserted, icon: "plus.circle")
                        Divider().padding(.leading, 44)
                        summaryRow("Actualizados", value: summary.totalUpdated, icon: "arrow.clockwise.circle")
                        Divider().padding(.leading, 44)
                        summaryRow("Sin cambios", value: summary.totalSkipped, icon: "equal.circle")
                        if summary.totalConflicts > 0 {
                            Divider().padding(.leading, 44)
                            summaryRow("Conflictos", value: summary.totalConflicts, icon: "exclamationmark.triangle")
                        }
                        if summary.totalErrors > 0 {
                            Divider().padding(.leading, 44)
                            summaryRow("Errores", value: summary.totalErrors, icon: "xmark.octagon")
                        }
                    }
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("Resumen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func summaryRow(_ title: LocalizedStringKey, value: Int, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)
            Text(title)
            Spacer()
            Text(value.formatted())
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct WirelessSyncInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    infoSection(
                        icon: "iphone.and.arrow.forward",
                        title: L10n.exact("Una forma sencilla de mover tus datos"),
                        text: L10n.exact("Transfiere tu información directamente entre tu iPhone y un dispositivo Android, o sincroniza ambos automáticamente. Puedes incluir todo el contenido compatible o elegir solo las categorías que necesitas.")
                    )
                    infoSection(
                        icon: "lock.shield",
                        title: L10n.exact("Una operación privada y segura"),
                        text: L10n.exact("Toda la información viaja fuertemente encriptada y únicamente entre los dos dispositivos enlazados. Tus datos no se publican ni se guardan en servicios externos.")
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Contenido que puedes transferir", systemImage: "square.grid.2x2")
                            .font(.headline)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(MigrationRecordType.allWirelessTypes, id: \.self) { type in
                                Text(MigrationRecordType.localizedName(type))
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Acerca de la transferencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoSection(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WirelessQRCodeScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) { }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onCode: (String) -> Void
        private var delivered = false

        init(onCode: @escaping (String) -> Void) {
            self.onCode = onCode
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !delivered else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let payload = barcode.payloadStringValue {
                    delivered = true
                    dataScanner.stopScanning()
                    onCode(payload)
                    return
                }
            }
        }
    }
}

#else

struct MigrationIOSAndroidView: View {
    var body: some View {
        ContentUnavailableView(
            "Transferencia móvil",
            systemImage: "iphone.and.arrow.forward",
            description: Text("El enlace inalámbrico entre iOS y Android está disponible desde el iPhone.")
        )
        .navigationTitle("Transferir datos")
    }
}

#endif
