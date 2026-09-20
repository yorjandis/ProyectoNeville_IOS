import CoreData
import PhotosUI
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import Photos
import UIKit
#elseif os(macOS)
import AppKit
import QuickLookUI
#endif

struct AttachmentExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.item] }
    static var writableContentTypes: [UTType] { [.item] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct PendingDiaryAttachment: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
    let contentType: UTType
}

struct PendingDiaryAttachmentsPicker: View {
    @Binding var attachments: [PendingDiaryAttachment]
    @State private var showFileImporter = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
#if os(iOS)
    @State private var showCamera = false
#endif
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(attachments) { attachment in
                HStack {
                    Image(systemName: attachment.contentType.conforms(to: .image) ? "photo" : "doc")
                        .foregroundStyle(.secondary)
                    Text(attachment.fileName)
                        .lineLimit(1)
                    Spacer()
                    Button(role: .destructive) {
                        attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quitar \(attachment.fileName)")
                }
            }

            Menu {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Archivo", systemImage: "folder.badge.plus")
                }

                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                    Label("Fotos", systemImage: "photo.badge.plus")
                }

#if os(iOS)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Cámara", systemImage: "camera")
                    }
                }
#endif
            } label: {
                Label(
                    isLoading ? "Preparando anexos…" : "Añadir anexo",
                    systemImage: isLoading ? "hourglass" : "paperclip.badge.ellipsis"
                )
            }
            .disabled(isLoading)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            Task { await loadFiles(result) }
        }
        .onChange(of: selectedPhotos) { _, items in
            guard !items.isEmpty else { return }
            Task { await loadPhotos(items) }
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPhotoCapture { image in
                guard let data = image.jpegData(compressionQuality: 1) else {
                    present(DiaryAttachmentError.invalidFile)
                    return
                }
                attachments.append(
                    PendingDiaryAttachment(
                        data: data,
                        fileName: "Foto-\(UUID().uuidString.prefix(8)).jpg",
                        contentType: .jpeg
                    )
                )
            }
            .ignoresSafeArea()
        }
#endif
        .alert("Anexos", isPresented: $showError) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func loadFiles(_ result: Result<[URL], Error>) async {
        isLoading = true
        defer { isLoading = false }
        do {
            for url in try result.get() {
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                let values = try url.resourceValues(forKeys: [.contentTypeKey, .nameKey])
                attachments.append(
                    PendingDiaryAttachment(
                        data: try Data(contentsOf: url, options: .mappedIfSafe),
                        fileName: values.name ?? url.lastPathComponent,
                        contentType: values.contentType ?? UTType(filenameExtension: url.pathExtension) ?? .data
                    )
                )
            }
        } catch {
            present(error)
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        isLoading = true
        defer {
            isLoading = false
            selectedPhotos = []
        }
        do {
            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw DiaryAttachmentError.invalidFile
                }
                let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) }) ?? .image
                let fileExtension = type.preferredFilenameExtension ?? "img"
                attachments.append(
                    PendingDiaryAttachment(
                        data: data,
                        fileName: "Foto-\(UUID().uuidString.prefix(8)).\(fileExtension)",
                        contentType: type
                    )
                )
            }
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

struct DiaryAttachmentsSection: View {
    @StateObject private var diarioModel = DiarioModel.shared
    @State private var attachments: [DiarioAttachment] = []
    @State private var previewAttachment: DiarioAttachment?
    @State private var renameAttachment: DiarioAttachment?
    @State private var moveAttachment: DiarioAttachment?
    @State private var renameText = ""
    @State private var exportDocument: AttachmentExportDocument?
    @State private var exportContentType = UTType.data
    @State private var exportFileName = "archivo"
    @State private var showExporter = false
    @State private var isWorking = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    private let diario: Diario

    init(diario: Diario) {
        self.diario = diario
        _attachments = State(
            initialValue: (try? DiaryAttachmentStore.shared.attachments(for: diario)) ?? []
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Anexos (\(attachments.count))", systemImage: "paperclip")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 6) {
                ForEach(attachments) { attachment in
                    attachmentRow(attachment)
                }
            }
            .padding(.leading, 8)
        }
        .onAppear { reloadAttachments() }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in reloadAttachments() }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in reloadAttachments() }
        .sheet(item: $previewAttachment) { attachment in
            AttachmentPreviewView(attachment: attachment)
        }
        .sheet(item: $moveAttachment) { attachment in
            MoveDiaryAttachmentView(attachment: attachment)
        }
        .alert("Renombrar anexo", isPresented: renameAlertBinding) {
            TextField("Nombre del archivo", text: $renameText)
            Button("Cancelar", role: .cancel) {
                renameAttachment = nil
            }
            Button("Guardar") {
                guard let attachment = renameAttachment else { return }
                do {
                    try DiaryAttachmentStore.shared.rename(attachment, to: renameText)
                } catch {
                    present(error)
                }
                renameAttachment = nil
            }
        }
        .alert("Anexos", isPresented: $showAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFileName
        ) { result in
            if case .failure(let error) = result {
                present(error)
            }
            exportDocument = nil
        }
    }

    @ViewBuilder
    private func attachmentRow(_ attachment: DiarioAttachment) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName(for: attachment))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName ?? "Archivo")
                    .lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: attachment.fileSize, countStyle: .file))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button {
                    previewAttachment = attachment
                } label: {
                    Label("Visualizar", systemImage: "eye")
                }
                Button {
                    renameAttachment = attachment
                    renameText = attachment.fileName ?? ""
                } label: {
                    Label("Renombrar", systemImage: "pencil")
                }
                Button {
                    moveAttachment = attachment
                } label: {
                    Label("Mover a otra entrada", systemImage: "arrow.right.doc.on.clipboard")
                }
                .disabled(diarioModel.list.count < 2)
                Button {
                    Task { await prepareExport(attachment) }
                } label: {
                    Label("Exportar archivo", systemImage: "square.and.arrow.up")
                }
#if os(iOS)
                if contentType(for: attachment).conforms(to: .image) {
                    Button {
                        Task { await saveImageToPhotos(attachment) }
                    } label: {
                        Label("Guardar en Fotos", systemImage: "photo.on.rectangle")
                    }
                }
#endif
                Divider()
                Button(role: .destructive) {
                do {
                    try DiaryAttachmentStore.shared.delete(attachment)
                    reloadAttachments()
                } catch {
                        present(error)
                    }
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 32, height: 32)
            }
            .menuStyle(.borderlessButton)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            previewAttachment = attachment
        }
        .accessibilityElement(children: .combine)
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(
            get: { renameAttachment != nil },
            set: { if !$0 { renameAttachment = nil } }
        )
    }

    private func prepareExport(_ attachment: DiarioAttachment) async {
        do {
            isWorking = true
            defer { isWorking = false }
            let data = try await DiaryAttachmentStore.shared.decryptedData(for: attachment)
            exportDocument = AttachmentExportDocument(data: data)
            exportContentType = contentType(for: attachment)
            exportFileName = attachment.fileName ?? "archivo"
            showExporter = true
        } catch {
            present(error)
        }
    }

#if os(iOS)
    private func saveImageToPhotos(_ attachment: DiarioAttachment) async {
        do {
            isWorking = true
            defer { isWorking = false }
            let data = try await DiaryAttachmentStore.shared.decryptedData(for: attachment)
            guard let image = UIImage(data: data) else {
                throw DiaryAttachmentError.invalidFile
            }
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            present(error)
        }
    }
#endif

    private func contentType(for attachment: DiarioAttachment) -> UTType {
        attachment.utiString.flatMap(UTType.init) ?? .data
    }

    private func iconName(for attachment: DiarioAttachment) -> String {
        let type = contentType(for: attachment)
        if type.conforms(to: .image) { return "photo" }
        if type.conforms(to: .pdf) { return "doc.richtext" }
        if type.conforms(to: .spreadsheet) { return "tablecells" }
        if type.conforms(to: .presentation) { return "rectangle.on.rectangle" }
        if type.conforms(to: .text) { return "doc.text" }
        return "doc"
    }

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }

    private func reloadAttachments() {
        do {
            attachments = try DiaryAttachmentStore.shared.attachments(for: diario)
        } catch {
            present(error)
        }
    }
}

struct MoveDiaryAttachmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diarioModel = DiarioModel.shared
    @State private var searchText = ""
    @State private var destinationToConfirm: Diario?
    @State private var errorMessage = ""
    @State private var showError = false

    let attachment: DiarioAttachment

    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredEntries) { entry in
                        Button {
                            destinationToConfirm = entry
                        } label: {
                            destinationRow(entry)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(primaryTextColor)
                }
            }
            .navigationTitle("Mover anexo")
            .searchable(
                text: $searchText,
                placement: .automatic,
                prompt: "Buscar por título o contenido"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .foregroundStyle(primaryTextColor)
            .tint(.accentColor)
            .background(systemBackgroundColor)
        }
        .frame(minWidth: 420, minHeight: 420)
        .alert("Confirmar movimiento", isPresented: confirmationBinding) {
            Button("Cancelar", role: .cancel) {
                destinationToConfirm = nil
            }
            Button("Mover") {
                moveToSelectedDestination()
            }
        } message: {
            if let destinationToConfirm {
                Text("¿Mover “\(attachment.fileName ?? "Archivo")” a la entrada “\(destinationToConfirm.title ?? "Sin título")”?")
            }
        }
        .alert("No se pudo mover el anexo", isPresented: $showError) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var filteredEntries: [Diario] {
        let candidates = diarioModel.list.filter {
            $0.objectID != attachment.diario?.objectID
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return candidates }
        return candidates.filter { entry in
            (entry.title ?? "").localizedCaseInsensitiveContains(query)
                || (entry.content ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { destinationToConfirm != nil },
            set: { if !$0 { destinationToConfirm = nil } }
        )
    }

    private func destinationRow(_ entry: Diario) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(entry.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                 ? entry.title ?? ""
                 : "Entrada sin título")
                .font(.headline)
                .lineLimit(1)

            if let content = entry.content?.trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(2)
            }

            if let date = entry.fecha {
                Text(date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(tertiaryTextColor)
            }
        }
        .foregroundStyle(primaryTextColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func moveToSelectedDestination() {
        guard let destination = destinationToConfirm else { return }
        do {
            try DiaryAttachmentStore.shared.move(attachment, to: destination)
            destinationToConfirm = nil
            dismiss()
        } catch {
            destinationToConfirm = nil
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private var primaryTextColor: Color {
#if os(iOS)
        Color(uiColor: .label)
#else
        Color(nsColor: .labelColor)
#endif
    }

    private var secondaryTextColor: Color {
#if os(iOS)
        Color(uiColor: .secondaryLabel)
#else
        Color(nsColor: .secondaryLabelColor)
#endif
    }

    private var tertiaryTextColor: Color {
#if os(iOS)
        Color(uiColor: .tertiaryLabel)
#else
        Color(nsColor: .tertiaryLabelColor)
#endif
    }

    private var systemBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: .systemBackground)
#else
        Color(nsColor: .windowBackgroundColor)
#endif
    }
}

struct DiaryAttachmentImportMenu: View {
    @AppStorage(AppCons.UD_setting_DiarioAttachmentImageQuality)
    private var imageQuality = 0.82

    @State private var showFileImporter = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
#if os(iOS)
    @State private var showCamera = false
#endif
    @State private var isWorking = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    let diario: Diario

    var body: some View {
        Menu {
            Button {
                showFileImporter = true
            } label: {
                Label("Archivo", systemImage: "folder.badge.plus")
            }

            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Fotos", systemImage: "photo.badge.plus")
            }

#if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Cámara", systemImage: "camera")
                }
            }
#endif
        } label: {
            Label(
                isWorking ? "Importando anexo…" : "Añadir anexo",
                systemImage: isWorking ? "hourglass" : "paperclip.badge.ellipsis"
            )
        }
        .disabled(isWorking)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            Task { await importFiles(result) }
        }
        .onChange(of: selectedPhotos) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPhotos(items) }
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPhotoCapture { image in
                Task { await importCameraImage(image) }
            }
            .ignoresSafeArea()
        }
#endif
        .alert("Anexos", isPresented: $showAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func importFiles(_ result: Result<[URL], Error>) async {
        do {
            isWorking = true
            defer { isWorking = false }
            for url in try result.get() {
                try await DiaryAttachmentStore.shared.importFile(
                    from: url,
                    into: diario,
                    imageQuality: imageQuality
                )
            }
        } catch {
            present(error)
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        isWorking = true
        defer {
            isWorking = false
            selectedPhotos = []
        }

        do {
            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw DiaryAttachmentError.invalidFile
                }
                let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) }) ?? .image
                try await DiaryAttachmentStore.shared.importPhoto(
                    data: data,
                    contentType: type,
                    into: diario,
                    imageQuality: imageQuality
                )
            }
        } catch {
            present(error)
        }
    }

#if os(iOS)
    private func importCameraImage(_ image: UIImage) async {
        do {
            isWorking = true
            defer { isWorking = false }
            guard let data = image.jpegData(compressionQuality: 1) else {
                throw DiaryAttachmentError.invalidFile
            }
            try await DiaryAttachmentStore.shared.importPhoto(
                data: data,
                contentType: .jpeg,
                into: diario,
                imageQuality: imageQuality
            )
        } catch {
            present(error)
        }
    }
#endif

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}

struct AttachmentPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var temporaryURL: URL?
    @State private var errorMessage: String?

    let attachment: DiarioAttachment

    var body: some View {
        NavigationStack {
            Group {
                if let temporaryURL {
                    QuickLookFileView(url: temporaryURL)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "No se pudo abrir el archivo",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    ProgressView("Descifrando…")
                }
            }
            .navigationTitle(attachment.fileName ?? "Anexo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .task { await preparePreview() }
        .onDisappear {
            guard let temporaryURL else { return }
            try? FileManager.default.removeItem(at: temporaryURL)
        }
    }

    private func preparePreview() async {
        do {
            let data = try await DiaryAttachmentStore.shared.decryptedData(for: attachment)
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("NevilleAttachmentPreviews", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(attachment.fileName ?? UUID().uuidString)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            temporaryURL = fileURL
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if os(iOS)
struct CameraPhotoCapture: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }
    }
}

private struct QuickLookFileView: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {
        context.coordinator.url = url
        controller.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
        }
    }
}
#elseif os(macOS)
private struct QuickLookFileView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)
        view?.previewItem = url as NSURL
        return view ?? QLPreviewView()
    }

    func updateNSView(_ view: QLPreviewView, context: Context) {
        view.previewItem = url as NSURL
        view.refreshPreviewItem()
    }
}
#endif
