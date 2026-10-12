import CoreData
import CoreImage
import ImageIO
import PhotosUI
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import PDFKit
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
    @State private var showPhotosPicker = false
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

                Button {
                    showPhotosPicker = true
                } label: {
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
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images
        )
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

private struct DiaryAttachmentPreviewPresentationModifier: ViewModifier {
    @Binding var attachment: DiarioAttachment?

    @ViewBuilder
    func body(content: Content) -> some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            content.fullScreenCover(item: $attachment) { item in
                AttachmentPreviewView(attachment: item)
            }
        } else {
            content.sheet(item: $attachment) { item in
                AttachmentPreviewView(attachment: item)
            }
        }
#else
        content.sheet(item: $attachment) { item in
            AttachmentPreviewView(attachment: item)
        }
#endif
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
    private let horizontal: Bool

    init(diario: Diario, horizontal: Bool = false) {
        self.diario = diario
        self.horizontal = horizontal
        _attachments = State(
            initialValue: (try? DiaryAttachmentStore.shared.attachments(for: diario)) ?? []
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !horizontal {
                Label("Anexos (\(attachments.count))", systemImage: "paperclip")
                    .font(.subheadline.weight(.semibold))
            }

            if horizontal {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(attachments) { attachment in
                            horizontalAttachmentRow(attachment)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                VStack(spacing: 6) {
                    ForEach(attachments) { attachment in
                        attachmentRow(attachment)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .onAppear { reloadAttachments() }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in reloadAttachments() }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in reloadAttachments() }
        .modifier(DiaryAttachmentPreviewPresentationModifier(attachment: $previewAttachment))
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
            attachmentActionsMenu(attachment)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            previewAttachment = attachment
        }
        .accessibilityElement(children: .combine)
    }

    private func horizontalAttachmentRow(_ attachment: DiarioAttachment) -> some View {
        HStack(spacing: 7) {
            Button {
                previewAttachment = attachment
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: iconName(for: attachment))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(attachment.fileName ?? "Archivo")
                            .lineLimit(1)
                        Text(ByteCountFormatter.string(fromByteCount: attachment.fileSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.black.opacity(0.62))
                    }
                }
                .font(.caption)
                .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            attachmentActionsMenu(attachment)
        }
        .padding(.leading, 10)
        .padding(.trailing, 3)
        .frame(height: 38)
        .background(.white.opacity(0.68), in: Capsule())
    }

    private func attachmentActionsMenu(_ attachment: DiarioAttachment) -> some View {
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
    @State private var showPhotosPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
#if os(iOS)
    @State private var showCamera = false
#endif
    @State private var isWorking = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    let diario: Diario
    var compact = false
    var onImportCompleted: () -> Void = {}

    var body: some View {
        Menu {
            Button {
                showFileImporter = true
            } label: {
                Label("Archivo", systemImage: "folder.badge.plus")
            }

            Button {
                showPhotosPicker = true
            } label: {
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
            if compact {
                Image(systemName: isWorking ? "hourglass" : "paperclip.badge.ellipsis")
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .accessibilityLabel(isWorking ? "Importando anexo" : "Añadir anexo")
            } else {
                Label(
                    isWorking ? "Importando anexo…" : "Añadir anexo",
                    systemImage: isWorking ? "hourglass" : "paperclip.badge.ellipsis"
                )
            }
        }
        .disabled(isWorking)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            Task { await importFiles(result) }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images
        )
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
            let urls = try result.get()
            for url in urls {
                try await DiaryAttachmentStore.shared.importFile(
                    from: url,
                    into: diario,
                    imageQuality: imageQuality
                )
            }
            if !urls.isEmpty {
                onImportCompleted()
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
            if !items.isEmpty {
                onImportCompleted()
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
            onImportCompleted()
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

private enum DiaryImageCropPreset: String, CaseIterable, Identifiable, Equatable {
    case original
    case square
    case fourThree
    case sixteenNine
    case guides

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: return "Original"
        case .square: return "1:1"
        case .fourThree: return "4:3"
        case .sixteenNine: return "16:9"
        case .guides: return "Guías"
        }
    }

    var aspectRatio: CGFloat? {
        switch self {
        case .original: return nil
        case .square: return 1
        case .fourThree: return 4 / 3
        case .sixteenNine: return 16 / 9
        case .guides: return nil
        }
    }
}

private struct DiaryImageEditState: Equatable {
    var quarterTurns = 0
    var isFlippedHorizontally = false
    var isFlippedVertically = false
    var brightness = 0.0
    var contrast = 1.0
    var cropPreset: DiaryImageCropPreset = .original
    var manualCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    static let identity = DiaryImageEditState()
}

private enum DiaryImageAdjustmentPanel: Equatable {
    case crop
    case light
}

private enum DiaryImageRenderer {
    private static let context = CIContext(options: [.cacheIntermediates: true])

    static func decodedImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let orientation = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.int32Value ?? 1
        let orientedImage = normalized(
            CIImage(cgImage: image).oriented(forExifOrientation: orientation)
        )
        return context.createCGImage(orientedImage, from: orientedImage.extent.integral)
    }

    static func render(
        _ source: CGImage,
        edits: DiaryImageEditState,
        appliesCrop: Bool = true
    ) -> CGImage? {
        var image = normalized(CIImage(cgImage: source))

        if edits.isFlippedHorizontally {
            image = normalized(
                image.transformed(
                    by: CGAffineTransform(translationX: image.extent.width, y: 0)
                        .scaledBy(x: -1, y: 1)
                )
            )
        }

        if edits.isFlippedVertically {
            image = normalized(
                image.transformed(
                    by: CGAffineTransform(translationX: 0, y: image.extent.height)
                        .scaledBy(x: 1, y: -1)
                )
            )
        }

        let normalizedTurns = ((edits.quarterTurns % 4) + 4) % 4
        if normalizedTurns != 0 {
            image = normalized(
                image.transformed(
                    by: CGAffineTransform(rotationAngle: CGFloat(normalizedTurns) * (.pi / 2))
                )
            )
        }

        image = image.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputBrightnessKey: edits.brightness,
                kCIInputContrastKey: edits.contrast
            ]
        )

        if appliesCrop, let targetRatio = edits.cropPreset.aspectRatio {
            let extent = image.extent
            let currentRatio = extent.width / extent.height
            let cropRect: CGRect
            if currentRatio > targetRatio {
                let width = extent.height * targetRatio
                cropRect = CGRect(
                    x: extent.midX - width / 2,
                    y: extent.minY,
                    width: width,
                    height: extent.height
                )
            } else {
                let height = extent.width / targetRatio
                cropRect = CGRect(
                    x: extent.minX,
                    y: extent.midY - height / 2,
                    width: extent.width,
                    height: height
                )
            }
            image = normalized(image.cropped(to: cropRect.integral))
        } else if appliesCrop, edits.cropPreset == .guides {
            let extent = image.extent
            let normalizedRect = edits.manualCropRect.standardized
            let cropRect = CGRect(
                x: extent.minX + normalizedRect.minX * extent.width,
                y: extent.minY + (1 - normalizedRect.maxY) * extent.height,
                width: normalizedRect.width * extent.width,
                height: normalizedRect.height * extent.height
            ).intersection(extent)
            if !cropRect.isNull, cropRect.width >= 1, cropRect.height >= 1 {
                image = normalized(image.cropped(to: cropRect.integral))
            }
        }

        return context.createCGImage(image, from: image.extent.integral)
    }

    static func encodedData(
        from image: CGImage,
        preferredContentType: UTType
    ) -> (data: Data, contentType: UTType)? {
        let candidates = [preferredContentType, .jpeg, .png]
        for contentType in candidates where contentType.conforms(to: .image) {
            let output = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                output,
                contentType.identifier as CFString,
                1,
                nil
            ) else { continue }

            CGImageDestinationAddImage(
                destination,
                image,
                [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary
            )
            if CGImageDestinationFinalize(destination) {
                return (output as Data, contentType)
            }
        }
        return nil
    }

    private static func normalized(_ image: CIImage) -> CIImage {
        let extent = image.extent.integral
        return image.transformed(
            by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY)
        )
    }
}

private enum DiaryCropGuideEdge: Equatable {
    case top
    case leading
    case trailing
    case bottom
}

private struct DiaryManualCropGuides: View {
    @Binding var cropRect: CGRect

    let imageFrame: CGRect
    let imagePixelSize: CGSize
    let onCommit: (CGRect) -> Void

    @State private var activeEdge: DiaryCropGuideEdge?
    @State private var dragStartRect: CGRect?

    private let minimumCropFraction: CGFloat = 0.08

    private var displayedCropRect: CGRect {
        CGRect(
            x: imageFrame.minX + cropRect.minX * imageFrame.width,
            y: imageFrame.minY + cropRect.minY * imageFrame.height,
            width: cropRect.width * imageFrame.width,
            height: cropRect.height * imageFrame.height
        )
    }

    var body: some View {
        ZStack {
            outsideMask
            guideLines
            draggableEdge(.top)
            draggableEdge(.leading)
            draggableEdge(.trailing)
            draggableEdge(.bottom)
            measurementLabel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var outsideMask: some View {
        Path { path in
            path.addRect(imageFrame)
            path.addRect(displayedCropRect)
        }
        .fill(.black.opacity(0.34), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    private var guideLines: some View {
        Path { path in
            path.addRect(displayedCropRect)

            for fraction in [CGFloat(1.0 / 3.0), CGFloat(2.0 / 3.0)] {
                let verticalX = displayedCropRect.minX + displayedCropRect.width * fraction
                path.move(to: CGPoint(x: verticalX, y: displayedCropRect.minY))
                path.addLine(to: CGPoint(x: verticalX, y: displayedCropRect.maxY))

                let horizontalY = displayedCropRect.minY + displayedCropRect.height * fraction
                path.move(to: CGPoint(x: displayedCropRect.minX, y: horizontalY))
                path.addLine(to: CGPoint(x: displayedCropRect.maxX, y: horizontalY))
            }
        }
        .stroke(.white.opacity(0.92), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        .allowsHitTesting(false)
    }

    private var measurementLabel: some View {
        let pixelWidth = max(1, Int(imagePixelSize.width * cropRect.width))
        let pixelHeight = max(1, Int(imagePixelSize.height * cropRect.height))
        return Text("\(pixelWidth) × \(pixelHeight) px")
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.55), in: Capsule())
            .position(
                x: displayedCropRect.midX,
                y: max(imageFrame.minY + 14, displayedCropRect.minY - 14)
            )
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func draggableEdge(_ edge: DiaryCropGuideEdge) -> some View {
        let hitThickness: CGFloat = 34
        let handleLength: CGFloat = 42

        switch edge {
        case .top, .bottom:
            let y = edge == .top ? displayedCropRect.minY : displayedCropRect.maxY
            Rectangle()
                .fill(.clear)
                .frame(width: displayedCropRect.width, height: hitThickness)
                .contentShape(Rectangle())
                .overlay {
                    Capsule()
                        .fill(.orange)
                        .frame(width: handleLength, height: 4)
                }
                .position(x: displayedCropRect.midX, y: y)
                .gesture(dragGesture(for: edge))

        case .leading, .trailing:
            let x = edge == .leading ? displayedCropRect.minX : displayedCropRect.maxX
            Rectangle()
                .fill(.clear)
                .frame(width: hitThickness, height: displayedCropRect.height)
                .contentShape(Rectangle())
                .overlay {
                    Capsule()
                        .fill(.orange)
                        .frame(width: 4, height: handleLength)
                }
                .position(x: x, y: displayedCropRect.midY)
                .gesture(dragGesture(for: edge))
        }
    }

    private func dragGesture(for edge: DiaryCropGuideEdge) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeEdge != edge || dragStartRect == nil {
                    activeEdge = edge
                    dragStartRect = cropRect
                }
                guard let start = dragStartRect,
                      imageFrame.width > 0,
                      imageFrame.height > 0 else { return }

                let horizontalDelta = value.translation.width / imageFrame.width
                let verticalDelta = value.translation.height / imageFrame.height
                var updated = start

                switch edge {
                case .top:
                    let newMinY = min(
                        max(0, start.minY + verticalDelta),
                        start.maxY - minimumCropFraction
                    )
                    updated.origin.y = newMinY
                    updated.size.height = start.maxY - newMinY
                case .leading:
                    let newMinX = min(
                        max(0, start.minX + horizontalDelta),
                        start.maxX - minimumCropFraction
                    )
                    updated.origin.x = newMinX
                    updated.size.width = start.maxX - newMinX
                case .trailing:
                    updated.size.width = min(
                        max(minimumCropFraction, start.width + horizontalDelta),
                        1 - start.minX
                    )
                case .bottom:
                    updated.size.height = min(
                        max(minimumCropFraction, start.height + verticalDelta),
                        1 - start.minY
                    )
                }

                cropRect = updated
            }
            .onEnded { _ in
                if let dragStartRect, dragStartRect != cropRect {
                    onCommit(dragStartRect)
                }
                activeEdge = nil
                dragStartRect = nil
            }
    }
}

struct AttachmentPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var temporaryURL: URL?
    @State private var errorMessage: String?
    @State private var sourceImage: CGImage?
    @State private var edits = DiaryImageEditState.identity
    @State private var undoStack: [DiaryImageEditState] = []
    @State private var redoStack: [DiaryImageEditState] = []
    @State private var activePanel: DiaryImageAdjustmentPanel?
    @State private var sliderBaseline: DiaryImageEditState?
    @State private var isSaving = false
    @State private var showDiscardConfirmation = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    let attachment: DiarioAttachment

    private var renderedImage: CGImage? {
        guard let sourceImage else { return nil }
        return DiaryImageRenderer.render(
            sourceImage,
            edits: edits,
            appliesCrop: edits.cropPreset != .guides
        )
    }

    private var hasEdits: Bool { edits != .identity }

    private var isPDFPreview: Bool {
        if let utiString = attachment.utiString,
           let contentType = UTType(utiString),
           contentType.conforms(to: .pdf) {
            return true
        }
        return (attachment.fileName as NSString?)?.pathExtension.lowercased() == "pdf"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(sourceImage == nil ? 0 : 0.94)
                    .ignoresSafeArea()

                if let renderedImage {
                    imageCanvas(renderedImage)
                } else if let temporaryURL {
#if os(iOS)
                    if isPDFPreview {
                        DiaryPDFPreviewView(url: temporaryURL)
                    } else {
                        QuickLookFileView(url: temporaryURL)
                    }
#else
                    QuickLookFileView(url: temporaryURL)
#endif
                } else if let errorMessage {
                    ContentUnavailableView(
                        "No se pudo abrir el archivo",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    ProgressView("Descifrando…")
                }

                if sourceImage != nil {
                    imageEditingOverlay
                }
            }
            .navigationTitle(attachment.fileName ?? "Anexo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { requestDismiss() }
                }
                if sourceImage != nil, hasEdits {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            saveEditedImage()
                        } label: {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Guardar")
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
        }
        .task { await preparePreview() }
        .confirmationDialog(
            "¿Cerrar sin guardar los cambios?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Descartar cambios", role: .destructive) { dismiss() }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("No se pudo guardar la imagen", isPresented: $showSaveError) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
        }
        .onDisappear {
            guard let temporaryURL else { return }
            try? FileManager.default.removeItem(at: temporaryURL)
        }
    }

    private func imageCanvas(_ image: CGImage) -> some View {
        GeometryReader { geometry in
            let imageFrame = fittedImageFrame(
                imageSize: CGSize(width: image.width, height: image.height),
                containerSize: geometry.size
            )

            Image(decorative: image, scale: 1, orientation: .up)
                .resizable()
                .frame(width: imageFrame.width, height: imageFrame.height)
                .position(x: imageFrame.midX, y: imageFrame.midY)

            if edits.cropPreset == .guides {
                DiaryManualCropGuides(
                    cropRect: $edits.manualCropRect,
                    imageFrame: imageFrame,
                    imagePixelSize: CGSize(width: image.width, height: image.height),
                    onCommit: commitManualCrop
                )
            }
        }
    }

    private func fittedImageFrame(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        let availableWidth = max(1, containerSize.width - 16)
        let availableHeight = max(1, containerSize.height - 86)
        let scale = min(
            availableWidth / max(1, imageSize.width),
            availableHeight / max(1, imageSize.height)
        )
        let fittedSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        return CGRect(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (availableHeight - fittedSize.height) / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private var imageEditingOverlay: some View {
        VStack(spacing: 10) {
            Spacer()

            if let activePanel {
                adjustmentPanel(activePanel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    editorButton("arrow.uturn.backward", label: "Deshacer", disabled: undoStack.isEmpty) {
                        undo()
                    }
                    editorButton("arrow.uturn.forward", label: "Rehacer", disabled: redoStack.isEmpty) {
                        redo()
                    }

                    Divider()
                        .frame(height: 26)
                        .overlay(.white.opacity(0.28))

                    editorButton("crop", label: "Recortar") {
                        togglePanel(.crop)
                    }
                    editorButton("rotate.left", label: "Girar a la izquierda") {
                        applyEdit { $0.quarterTurns -= 1 }
                    }
                    editorButton("rotate.right", label: "Girar a la derecha") {
                        applyEdit { $0.quarterTurns += 1 }
                    }
                    editorButton("arrow.left.and.right", label: "Voltear horizontalmente") {
                        applyEdit { $0.isFlippedHorizontally.toggle() }
                    }
                    editorButton("arrow.up.and.down", label: "Voltear verticalmente") {
                        applyEdit { $0.isFlippedVertically.toggle() }
                    }
                    editorButton("sun.max", label: "Brillo y contraste") {
                        togglePanel(.light)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                hideAdjustmentPanel()
            }
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .animation(.easeInOut(duration: 0.2), value: activePanel)
    }

    @ViewBuilder
    private func adjustmentPanel(_ panel: DiaryImageAdjustmentPanel) -> some View {
        switch panel {
        case .crop:
            VStack(alignment: .leading, spacing: 10) {
                Label("Recorte", systemImage: "crop")
                    .font(.headline)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(DiaryImageCropPreset.allCases) { preset in
                            Button(preset.title) {
                                applyEdit { $0.cropPreset = preset }
                            }
                            .buttonStyle(.bordered)
                            .tint(edits.cropPreset == preset ? .orange : .white.opacity(0.45))
                        }
                    }
                }
                .scrollIndicators(.hidden)

                if edits.cropPreset == .guides {
                    Text("Arrastra cualquiera de las cuatro líneas naranjas para ajustar el corte.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))
                    Button("Restablecer guías") {
                        applyEdit {
                            $0.manualCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                }
            }
            .modifier(TransparentImageAdjustmentPanel())

        case .light:
            VStack(alignment: .leading, spacing: 12) {
                Label("Brillo", systemImage: "sun.max")
                    .font(.subheadline.weight(.semibold))
                Slider(
                    value: brightnessBinding,
                    in: -0.5...0.5,
                    onEditingChanged: trackSliderEditing
                )
                Label("Contraste", systemImage: "circle.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                Slider(
                    value: contrastBinding,
                    in: 0.5...1.5,
                    onEditingChanged: trackSliderEditing
                )
                Button("Restablecer luz") {
                    applyEdit {
                        $0.brightness = 0
                        $0.contrast = 1
                    }
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
            }
            .modifier(TransparentImageAdjustmentPanel())
        }
    }

    private var brightnessBinding: Binding<Double> {
        Binding(get: { edits.brightness }, set: { edits.brightness = $0 })
    }

    private var contrastBinding: Binding<Double> {
        Binding(get: { edits.contrast }, set: { edits.contrast = $0 })
    }

    private func editorButton(
        _ systemImage: String,
        label: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(disabled ? 0.35 : 0.94))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(label)
        .help(label)
    }

    private func togglePanel(_ panel: DiaryImageAdjustmentPanel) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activePanel = activePanel == panel ? nil : panel
        }
    }

    private func hideAdjustmentPanel() {
        guard activePanel != nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            activePanel = nil
        }
    }

    private func applyEdit(_ mutation: (inout DiaryImageEditState) -> Void) {
        let previous = edits
        mutation(&edits)
        guard previous != edits else { return }
        undoStack.append(previous)
        redoStack.removeAll()
    }

    private func trackSliderEditing(_ isEditing: Bool) {
        if isEditing {
            sliderBaseline = edits
        } else if let sliderBaseline {
            self.sliderBaseline = nil
            guard sliderBaseline != edits else { return }
            undoStack.append(sliderBaseline)
            redoStack.removeAll()
        }
    }

    private func commitManualCrop(previousRect: CGRect) {
        var previous = edits
        previous.manualCropRect = previousRect
        guard previous != edits else { return }
        undoStack.append(previous)
        redoStack.removeAll()
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(edits)
        edits = previous
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(edits)
        edits = next
    }

    private func requestDismiss() {
        if hasEdits {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func preparePreview() async {
        do {
            let data = try await DiaryAttachmentStore.shared.decryptedData(for: attachment)
            if let image = DiaryImageRenderer.decodedImage(from: data) {
                sourceImage = image
                return
            }

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

    private func saveEditedImage() {
        guard let originalImage = sourceImage,
              let renderedImage = DiaryImageRenderer.render(originalImage, edits: edits) else { return }
        let preferredType = UTType(attachment.utiString ?? "") ?? .jpeg
        guard let encoded = DiaryImageRenderer.encodedData(
            from: renderedImage,
            preferredContentType: preferredType
        ) else {
            saveErrorMessage = DiaryAttachmentError.invalidFile.localizedDescription
            showSaveError = true
            return
        }

        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await DiaryAttachmentStore.shared.replaceData(
                    for: attachment,
                    with: encoded.data,
                    contentType: encoded.contentType
                )
                sourceImage = renderedImage
                edits = .identity
                undoStack.removeAll()
                redoStack.removeAll()
                activePanel = nil
            } catch {
                saveErrorMessage = error.localizedDescription
                showSaveError = true
            }
        }
    }
}

private struct TransparentImageAdjustmentPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
            .padding(.horizontal, 20)
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

private struct DiaryPDFPreviewView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.backgroundColor = .systemBackground
        view.tintColor = .black
        view.document = PDFDocument(url: url)
        context.coordinator.observeSelections(in: view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
        view.tintColor = .black
        context.coordinator.applySelectionColor(in: view)
    }

    static func dismantleUIView(_ view: PDFView, coordinator: Coordinator) {
        coordinator.stopObserving()
    }

    @MainActor
    final class Coordinator: NSObject {
        private weak var observedView: PDFView?

        func observeSelections(in view: PDFView) {
            stopObserving()
            observedView = view
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(selectionDidChange(_:)),
                name: .PDFViewSelectionChanged,
                object: view
            )
        }

        func applySelectionColor(in view: PDFView) {
            view.currentSelection?.color = UIColor.black.withAlphaComponent(0.38)
        }

        func stopObserving() {
            NotificationCenter.default.removeObserver(
                self,
                name: .PDFViewSelectionChanged,
                object: observedView
            )
            observedView = nil
        }

        @objc private func selectionDidChange(_ notification: Notification) {
            guard let view = notification.object as? PDFView else { return }
            applySelectionColor(in: view)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
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
