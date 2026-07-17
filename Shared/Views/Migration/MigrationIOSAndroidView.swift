import SwiftUI
import Combine
import UniformTypeIdentifiers
import LocalAuthentication

@MainActor
private final class MigrationIOSAndroidViewModel: ObservableObject {
    @Published var exportPassword = ""
    @Published var exportPasswordConfirmation = ""
    @Published var importPassword = ""
    @Published var exportDocument: MigrationDataDocument?
    @Published var lastExportCountsByType: [String: Int] = [:]
    @Published var lastExportBytes = 0
    @Published var lastExportId: String?
    @Published var lastImportCountsByType: [String: Int] = [:]
    @Published var lastImportSummary: MigrationSummary?
    @Published var lastImportPolicy: ImportPolicy = .skipExisting
    @Published var preview: ImportPreview?
    @Published var message: String?
    @Published var exportErrorMessage: String?
    @Published var isWorking = false
    @Published var isExporterPresented = false
    @Published var showOverwriteConfirmation = false

    private let service = MyAppMigrationService()

    var canExport: Bool {
        exportPasswordLengthIsValid && passwordsMatch
    }

    var exportPasswordCharacterCount: Int {
        exportPassword.precomposedStringWithCanonicalMapping.unicodeScalars.count
    }

    var exportPasswordLengthIsValid: Bool {
        exportPasswordCharacterCount >= MigrationFormat.minimumPasswordCharacters
    }

    var passwordsMatch: Bool {
        !exportPasswordConfirmation.isEmpty && exportPassword == exportPasswordConfirmation
    }

    var canPreviewImport: Bool {
        !importPassword.isEmpty
    }

    var hasBlockingConflicts: Bool {
        preview?.conflicts.contains { !$0.reason.contains("idéntico") } == true
    }

    func prepareExport() {
        guard canExport else {
            exportErrorMessage = exportPasswordLengthIsValid
                ? "Las contraseñas no coinciden."
                : "La contraseña debe tener al menos \(MigrationFormat.minimumPasswordCharacters) caracteres."
            return
        }
        isWorking = true
        exportErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            defer { isWorking = false }
            do {
                let result = try await service.exportAsync(password: exportPassword)
                exportDocument = MigrationDataDocument(data: result.bytes)
                lastExportCountsByType = result.countsByType
                lastExportBytes = result.bytes.count
                lastExportId = result.exportId
                message = "Exportación preparada: \(exportedTotal) elementos listos para guardar."
                isExporterPresented = true
            } catch {
                exportDocument = nil
                lastExportCountsByType = [:]
                lastExportBytes = 0
                lastExportId = nil
                exportErrorMessage = "No se pudo preparar la exportación: \(error.localizedDescription)"
            }
        }
    }

    var exportedTotal: Int {
        lastExportCountsByType.values.reduce(0, +)
    }

    var hasExportSummary: Bool {
        !lastExportCountsByType.isEmpty || lastExportBytes > 0
    }

    var importedTotal: Int {
        lastImportCountsByType.values.reduce(0, +)
    }

    var hasImportSummary: Bool {
        lastImportSummary != nil
    }

    func buildPreview(from url: URL) {
        guard canPreviewImport else {
            message = "Escribe la contraseña del archivo antes de importar."
            return
        }
        isWorking = true
        defer { isWorking = false }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let bytes = try Data(contentsOf: url)
            preview = try service.preview(fileBytes: bytes, password: importPassword)
            lastImportCountsByType = [:]
            lastImportSummary = nil
            let total = preview?.countsByType.values.reduce(0, +) ?? 0
            message = "Vista previa lista: \(total) elementos."
        } catch {
            preview = nil
            lastImportCountsByType = [:]
            lastImportSummary = nil
            message = "No se pudo generar la vista previa: \(error.localizedDescription)"
        }
    }

    func importCurrentPreview(policy: ImportPolicy = .skipExisting) {
        guard let preview else {
            message = "Primero genera una vista previa del archivo."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let summary = try service.importPreview(preview, policy: policy)
            lastImportCountsByType = preview.countsByType
            lastImportSummary = summary
            lastImportPolicy = policy
            message = "Importación finalizada. Insertados: \(summary.inserted), actualizados: \(summary.updated), omitidos: \(summary.skipped), conflictos: \(summary.conflicts), errores: \(summary.errors)."
            self.preview = nil
            importPassword = ""
        } catch {
            lastImportCountsByType = [:]
            lastImportSummary = nil
            message = "No se pudo completar la importación: \(error.localizedDescription)"
        }
    }
}

struct MigrationIOSAndroidView: View {
    @StateObject private var viewModel = MigrationIOSAndroidViewModel()
    @State private var showImporter = false
    @State private var isMigrationUnlocked = false
    @State private var authPassword = ""
    @State private var authMessage: String?

    var body: some View {
        Form {
            exportableContentInfo()

            if isMigrationUnlocked {
                Section("Preparar archivo de migración") {
                    SecureField("Contraseña del archivo (mínimo 15 caracteres)", text: $viewModel.exportPassword)

                    Label {
                        Text(viewModel.exportPasswordLengthIsValid
                             ? "Longitud correcta"
                             : "Mínimo \(MigrationFormat.minimumPasswordCharacters) caracteres (\(viewModel.exportPasswordCharacterCount)/\(MigrationFormat.minimumPasswordCharacters))")
                    } icon: {
                        Image(systemName: viewModel.exportPasswordLengthIsValid
                              ? "checkmark.circle.fill"
                              : "circle")
                    }
                    .font(.footnote)
                    .foregroundStyle(viewModel.exportPasswordLengthIsValid ? Color.green : Color.secondary)

                    SecureField("Repetir contraseña", text: $viewModel.exportPasswordConfirmation)

                    if !viewModel.exportPasswordConfirmation.isEmpty {
                        Label(
                            viewModel.passwordsMatch ? "Las contraseñas coinciden" : "Las contraseñas no coinciden",
                            systemImage: viewModel.passwordsMatch ? "checkmark.circle.fill" : "exclamationmark.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(viewModel.passwordsMatch ? Color.green : Color.red)
                    }

                    Button {
                        viewModel.prepareExport()
                    } label: {
                        if viewModel.isWorking {
                            Label("Cifrando archivo…", systemImage: "lock.rotation")
                        } else {
                            Label("Crear archivo .ypgexp", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(!viewModel.canExport || viewModel.isWorking)

                    if viewModel.isWorking {
                        ProgressView("Preparando exportación segura…")
                    }

                    if let exportErrorMessage = viewModel.exportErrorMessage {
                        Text(exportErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("Tus datos se preparan en un archivo seguro y protegido. La contraseña no se guarda y se requiere para la importación.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if viewModel.hasExportSummary {
                        exportSummary()
                    }
                }

                Section("Importar archivo de migración ") {
                    SecureField("Contraseña del archivo", text: $viewModel.importPassword)

                    Button {
                        showImporter = true
                    } label: {
                        Label("Seleccionar archivo .ypgexp", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!viewModel.canPreviewImport || viewModel.isWorking)

                    if let preview = viewModel.preview {
                        previewSummary(preview)

                        if !preview.errors.isEmpty {
                            validationList(title: "Errores", items: preview.errors)
                        }

                        if !preview.conflicts.isEmpty {
                            conflictList(preview.conflicts)
                        }

                        Button {
                            if viewModel.hasBlockingConflicts {
                                viewModel.showOverwriteConfirmation = true
                            } else {
                                viewModel.importCurrentPreview()
                            }
                        } label: {
                            Label("Importar elementos válidos", systemImage: "checkmark.circle")
                        }
                        .disabled(viewModel.isWorking || !preview.errors.isEmpty)
                    }

                    if viewModel.hasImportSummary {
                        importSummary()
                    }
                }

                if let message = viewModel.message {
                    Section("Resumen") {
                        Text(message)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                authenticationSection()
            }
        }
        #if os(macOS)
        .padding(20)
        #endif
        .navigationTitle("Migración iOS / Android")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fileExporter(
            isPresented: $viewModel.isExporterPresented,
            document: viewModel.exportDocument ?? MigrationDataDocument(),
            contentType: .ypgExport,
            defaultFilename: "neville-ios-export.ypgexp"
        ) { result in
            switch result {
            case .success:
                viewModel.message = "Archivo exportado correctamente: \(viewModel.exportedTotal) elementos en \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.lastExportBytes), countStyle: .file))."
                viewModel.exportPassword = ""
                viewModel.exportPasswordConfirmation = ""
                viewModel.exportDocument = nil
            case .failure(let error):
                viewModel.message = "No se pudo guardar el archivo exportado: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.ypgExport, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.buildPreview(from: url)
                } else {
                    viewModel.preview = nil
                    viewModel.lastImportCountsByType = [:]
                    viewModel.lastImportSummary = nil
                    viewModel.message = "No se seleccionó ningún archivo para importar."
                }
            case .failure(let error):
                viewModel.preview = nil
                viewModel.lastImportCountsByType = [:]
                viewModel.lastImportSummary = nil
                viewModel.message = "No se pudo abrir el selector de archivos: \(error.localizedDescription)"
            }
        }
        .confirmationDialog(
            "Hay conflictos con datos locales. No se sobrescribe nada sin confirmación.",
            isPresented: $viewModel.showOverwriteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Omitir conflictos e importar lo nuevo") {
                viewModel.importCurrentPreview(policy: .skipExisting)
            }
            Button("Sobrescribir registros", role: .destructive) {
                viewModel.importCurrentPreview(policy: .overwriteExisting)
            }
            Button("Cancelar", role: .cancel) { }
        }
    }

    private func exportableContentInfo() -> some View {
        Section("Datos que se pueden exportar") {
            Text("La migración exporta, de manera segura y cifrada, los siguientes datos:")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(exportableContentTypes, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
            }
        }
    }

    private func authenticationSection() -> some View {
        Section("Acceso protegido") {
            Text("Por seguridad, desbloquea la migración antes de proceder.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                authenticateWithDeviceOwner()
            } label: {
                Label("Desbloquear con biometría o código", systemImage: "key.viewfinder")
            }

            if KeychainHelper.shared.getPassword() != nil {
                SecureField("Contraseña de la app", text: $authPassword)

                Button {
                    authenticateWithStoredPassword()
                } label: {
                    Label("Desbloquear con contraseña", systemImage: "lock.open")
                }
                .disabled(authPassword.isEmpty)
            } else {
                Text("Si este dispositivo no admite autenticación biométrica o código compatible, crea una contraseña de la app para proteger el acceso.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                createPasswordAccess
            }

            if let authMessage {
                Text(authMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var createPasswordAccess: some View {
        #if os(macOS)
        Button {
            showWindow(for: CreatePasswordView(),
                       environmentObjects: [],
                       title: "Crear contraseña",
                       size: AppCons.windows_size_content_small,
                       isModal: true)
        } label: {
            Label("Crear contraseña de la app", systemImage: "lock.badge.plus")
        }
        #else
        NavigationLink {
            CreatePasswordView()
        } label: {
            Label("Crear contraseña de la app", systemImage: "lock.badge.plus")
        }
        #endif
    }

    private func authenticateWithDeviceOwner() {
        let context = LAContext()
        var error: NSError?
        let reason = "Autentícate para acceder a la exportación e importación de datos."

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authMessage = "No hay biometría/código disponible. Usa la contraseña de la app si existe."
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    isMigrationUnlocked = true
                    authPassword = ""
                    authMessage = nil
                } else {
                    authMessage = evalError?.localizedDescription ?? "No se pudo autenticar."
                }
            }
        }
    }

    private func authenticateWithStoredPassword() {
        guard let storedPassword = KeychainHelper.shared.getPassword() else {
            authMessage = "No hay una contraseña de la app configurada."
            return
        }

        if authPassword == storedPassword {
            isMigrationUnlocked = true
            authPassword = ""
            authMessage = nil
        } else {
            authMessage = "Contraseña incorrecta."
        }
    }

    private func exportSummary() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resumen exportado")
                .font(.headline)

            ForEach(viewModel.lastExportCountsByType.keys.sorted(), id: \.self) { key in
                compactSummaryLine(displayName(for: key), value: viewModel.lastExportCountsByType[key] ?? 0)
            }

            if viewModel.lastExportBytes > 0 {
                compactSummaryLine(
                    "Tamaño",
                    detail: ByteCountFormatter.string(fromByteCount: Int64(viewModel.lastExportBytes), countStyle: .file)
                )
            }

            if let exportId = viewModel.lastExportId {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(exportId)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func previewSummary(_ preview: ImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vista previa")
                .font(.headline)
            ForEach(preview.countsByType.keys.sorted(), id: \.self) { key in
                compactSummaryLine(displayName(for: key), value: preview.countsByType[key] ?? 0)
            }
        }
    }

    private func importSummary() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resumen importado")
                .font(.headline)

            ForEach(viewModel.lastImportCountsByType.keys.sorted(), id: \.self) { key in
                compactSummaryLine(displayName(for: key), value: viewModel.lastImportCountsByType[key] ?? 0)
            }

            if let summary = viewModel.lastImportSummary {
                Divider()

                summaryRow("Procesados", value: viewModel.importedTotal)
                summaryRow("Insertados", value: summary.inserted)
                summaryRow("Actualizados", value: summary.updated)
                summaryRow("Omitidos", value: summary.skipped)
                summaryRow("Conflictos", value: summary.conflicts)
                summaryRow("Errores", value: summary.errors)

                Text("Política: \(viewModel.lastImportPolicy == .overwriteExisting ? "sobrescribir mismo ID" : "no sobrescribir")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func summaryRow(_ title: String, value: Int) -> some View {
        compactSummaryLine(title, value: value)
    }

    private func compactSummaryLine(_ title: String, value: Int) -> some View {
        compactSummaryLine(title, detail: "\(value)")
    }

    private func compactSummaryLine(_ title: String, detail: String) -> some View {
        Text("\(title): \(detail)")
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func validationList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func conflictList(_ conflicts: [ImportConflict]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conflictos")
                .font(.headline)

            ForEach(conflictSummaries(from: conflicts), id: \.id) { summary in
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.title)
                        .font(.subheadline)
                    Text(summary.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func conflictSummaries(from conflicts: [ImportConflict]) -> [ConflictSummary] {
        let grouped = Dictionary(grouping: conflicts) { conflict in
            ConflictSummaryKey(type: conflict.type, kind: conflictKind(for: conflict))
        }

        return grouped
            .map { key, values in
                ConflictSummary(
                    id: "\(key.type)-\(key.kind.rawValue)",
                    title: conflictTitle(type: key.type, kind: key.kind, count: values.count),
                    detail: conflictDetail(kind: key.kind)
                )
            }
            .sorted { left, right in
                left.title.localizedCaseInsensitiveCompare(right.title) == .orderedAscending
            }
    }

    private func conflictKind(for conflict: ImportConflict) -> ConflictKind {
        conflict.reason.localizedCaseInsensitiveContains("idéntico") ? .existing : .conflict
    }

    private func conflictTitle(type: String, kind: ConflictKind, count: Int) -> String {
        let name = displayName(for: type)
        switch kind {
        case .existing:
            return "\(name) existentes: \(count)"
        case .conflict:
            return "\(name) con conflicto: \(count)"
        }
    }

    private func conflictDetail(kind: ConflictKind) -> String {
        switch kind {
        case .existing:
            return "Ya existen en iOS y se omitirán durante la importación."
        case .conflict:
            return "No se sobrescribirán sin confirmación manual."
        }
    }

    private func displayName(for type: String) -> String {
        switch type {
        case MigrationRecordType.note: return "Notas"
        case MigrationRecordType.diary: return "Diario"
        case MigrationRecordType.agenda: return "Agenda"
        case MigrationRecordType.goal: return "Metas activas"
        case MigrationRecordType.archivedGoal: return "Metas archivadas"
        case MigrationRecordType.personalPhrase: return "Frases personales"
        case MigrationRecordType.personalReflection: return "Reflexiones personales"
        case MigrationRecordType.dayRitualArchive: return "Ritual del día"
        case MigrationRecordType.calmPersonalPhrase: return "Frases de Calma"
            default: return type
        }
    }

    private var exportableContentTypes: [String] {
        [
            "Notas",
            "Entradas de diario",
            "Entradas de agenda sin recordatorios",
            "Metas activas, completadas y archivadas",
            "Frases personales",
            "Reflexiones personales",
            "Ritual del día archivado",
            "Frases personales de Espacio Calma"
        ]
    }
}

private enum ConflictKind: String {
    case existing
    case conflict
}

private struct ConflictSummaryKey: Hashable {
    let type: String
    let kind: ConflictKind
}

private struct ConflictSummary {
    let id: String
    let title: String
    let detail: String
}
