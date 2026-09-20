import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    nonisolated static let nevilleDiarySQLiteBackup = UTType(
        exportedAs: "com.ypg.neville.diary-backup.sqlite",
        conformingTo: .database
    )
}

struct DiarySQLiteBackupView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case export
        case restore

        var id: Self { self }
        var title: String { self == .export ? "Exportar" : "Restaurar" }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .export
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var selectedURL: URL?
    @State private var archive: DiaryBackupArchive?
    @State private var preview: DiaryBackupPreview?
    @State private var policy: DiaryBackupConflictPolicy = .keepExisting
    @State private var isWorking = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportURL: URL?
    @State private var showRestoreConfirmation = false
    @State private var alertTitle = "Copia del Diario"
    @State private var alertMessage = ""
    @State private var showAlert = false

    let onRestore: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Picker("Operación", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .export {
                    exportSections
                } else {
                    restoreSections
                }
            }
#if os(iOS)
            .contentMargins(.horizontal, 16, for: .scrollContent)
#endif
            .navigationTitle("Copia completa del Diario")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .disabled(isWorking)
            .overlay {
                if isWorking {
                    ZStack {
                        Color.black.opacity(0.12).ignoresSafeArea()
                        ProgressView(mode == .export ? "Creando copia cifrada…" : "Procesando copia…")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 480, minHeight: 520)
#endif
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.nevilleDiarySQLiteBackup, .database, .data]
        ) { result in
            handleSelectedFile(result)
        }
        .fileMover(
            isPresented: $showExporter,
            file: exportURL
        ) { result in
            handleExportResult(result)
        } onCancellation: {
            cleanupTemporaryExport()
        }
        .confirmationDialog(
            "Confirmar restauración",
            isPresented: $showRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restaurar ahora", role: policy == .keepExisting ? nil : .destructive) {
                Task { await restoreBackup() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(policy.explanation)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onChange(of: mode) { _, _ in resetTransientState() }
    }

    @ViewBuilder
    private var exportSections: some View {
        Section("Contenido") {
            Label("Todas las entradas del Diario", systemImage: "book.closed")
            Label("Todos sus anexos y metadatos", systemImage: "paperclip")
        }

        Section {
            SecureField("Contraseña", text: $password)
                .textContentType(.newPassword)
            SecureField("Repetir contraseña", text: $passwordConfirmation)
                .textContentType(.newPassword)
        } header: {
            Text("Contraseña de la copia")
        } footer: {
            Text("La contraseña no se guarda ni puede recuperarse. Será necesaria para restaurar esta copia.")
        }

        Section {
            Button {
                Task { await prepareExport() }
            } label: {
                Label("Crear archivo SQLite", systemImage: "externaldrive.badge.plus")
            }
            .disabled(password.count < 8 || password != passwordConfirmation)
        } footer: {
            Text("La copia queda protegida con tu contraseña. Nadie podrá leer las entradas ni los anexos sin ella.")
        }
    }

    @ViewBuilder
    private var restoreSections: some View {
        Section("Archivo") {
            Button {
                showImporter = true
            } label: {
                Label(selectedURL?.lastPathComponent ?? "Seleccionar copia SQLite", systemImage: "doc.badge.plus")
                    .lineLimit(1)
            }
        }

        Section("Contraseña") {
            SecureField("Contraseña de la copia", text: $password)
                .textContentType(.password)
            Button("Analizar copia") {
                Task { await analyzeBackup() }
            }
            .disabled(selectedURL == nil || password.isEmpty)
        }

        if let preview {
            Section("Resumen") {
                LabeledContent("Entradas", value: preview.entryCount.formatted())
                LabeledContent("Anexos", value: preview.attachmentCount.formatted())
                LabeledContent("Entradas ya existentes", value: preview.conflictingEntries.formatted())
                LabeledContent("Anexos ya existentes", value: preview.conflictingAttachments.formatted())
            }

            Section("Conflictos") {
                Picker("Aplicar a todos", selection: $policy) {
                    ForEach(DiaryBackupConflictPolicy.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                Text(policy.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(policy == .keepExisting ? "Restaurar elementos nuevos" : "Restaurar y reemplazar") {
                    showRestoreConfirmation = true
                }
            }
        }
    }

    @MainActor
    private func prepareExport() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let url = try await DiarySQLiteBackupService().export(password: password)
            exportURL = url
            showExporter = true
        } catch {
            present(error, title: "No se pudo crear la copia")
        }
    }

    private func handleSelectedFile(_ result: Result<URL, Error>) {
        do {
            selectedURL = try result.get()
            archive = nil
            preview = nil
            password = ""
        } catch {
            present(error, title: "No se pudo seleccionar el archivo")
        }
    }

    @MainActor
    private func analyzeBackup() async {
        guard let selectedURL else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let loadedArchive = try await DiarySQLiteBackupService().loadArchive(from: selectedURL, password: password)
            archive = loadedArchive
            preview = try DiarySQLiteBackupService().preview(loadedArchive)
        } catch {
            archive = nil
            preview = nil
            present(error, title: "No se pudo abrir la copia")
        }
    }

    @MainActor
    private func restoreBackup() async {
        guard let archive else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let summary = try await DiarySQLiteBackupService().restore(archive, policy: policy)
            self.archive = nil
            password = ""
            onRestore()
            alertTitle = "Restauración completada"
            alertMessage = "Entradas añadidas: \(summary.insertedEntries). Entradas reemplazadas: \(summary.replacedEntries). Anexos añadidos: \(summary.insertedAttachments). Anexos reemplazados: \(summary.replacedAttachments)."
            showAlert = true
        } catch {
            present(error, title: "No se pudo restaurar la copia")
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        defer {
            cleanupTemporaryExport()
            password = ""
            passwordConfirmation = ""
        }
        if case .failure(let error) = result {
            present(error, title: "No se pudo exportar")
        }
    }

    private func cleanupTemporaryExport() {
        guard let exportURL else { return }
        try? FileManager.default.removeItem(at: exportURL.deletingLastPathComponent())
        self.exportURL = nil
    }

    private func resetTransientState() {
        password = ""
        passwordConfirmation = ""
        archive = nil
        preview = nil
        selectedURL = nil
    }

    private func present(_ error: Error, title: String) {
        alertTitle = title
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
