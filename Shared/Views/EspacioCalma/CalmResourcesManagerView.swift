import SwiftUI
import Combine
import UniformTypeIdentifiers
import PhotosUI
@preconcurrency import AVFoundation

extension AVAssetExportSession: @retroactive @unchecked Sendable {}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(MediaPlayer)
@preconcurrency import MediaPlayer
#endif

private struct CalmManagedAsset: Identifiable, Equatable {
    let name: String
    let url: URL

    var id: String { name }
}

private final class CalmAudioPreviewController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var playingAssetID: String?
    private var player: AVAudioPlayer?

    func togglePlayback(for asset: CalmManagedAsset) {
        if playingAssetID == asset.id {
            stop()
            return
        }
        play(asset)
    }

    func stop() {
        player?.stop()
        player = nil
        playingAssetID = nil
    }

    private func play(_ asset: CalmManagedAsset) {
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: asset.url)
            newPlayer.delegate = self
            newPlayer.numberOfLoops = 0
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            playingAssetID = asset.id
        } catch {
            msg("Error reproduciendo preview de música:", error)
            stop()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playingAssetID = nil
    }
}

private enum CalmManagedAssetKind {
    case background
    case music
}

private final class CalmResourceStore: ObservableObject, @unchecked Sendable {
    @Published var backgroundAssets: [CalmManagedAsset] = []
    @Published var musicAssets: [CalmManagedAsset] = []

    private let fileManager = FileManager.default

    init() {
        reload()
    }

    func reload() {
        ensureDirectories()
        backgroundAssets = listAssets(kind: .background)
        musicAssets = listAssets(kind: .music)
    }

    func importBackground(from sourceURL: URL) {
        importAsset(from: sourceURL, kind: .background)
    }

    func importMusic(from sourceURL: URL) {
        importAsset(from: sourceURL, kind: .music)
    }

    func deleteBackground(_ asset: CalmManagedAsset) {
        deleteAsset(asset, kind: .background)
    }

    func deleteMusic(_ asset: CalmManagedAsset) {
        deleteAsset(asset, kind: .music)
    }

    private func importAsset(from sourceURL: URL, kind: CalmManagedAssetKind) {
        ensureDirectories()

        var didAccessScopedURL = false
        if sourceURL.startAccessingSecurityScopedResource() {
            didAccessScopedURL = true
        }
        defer {
            if didAccessScopedURL {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destinationDirectory = assetsDirectory(for: kind)
        let preferredName: String
        switch kind {
        case .background:
            preferredName = "User_image_\(Int64(Date().timeIntervalSince1970 * 1000))"
        case .music:
            preferredName = "User_musica_\(Int64(Date().timeIntervalSince1970 * 1000))"
        }

        if kind == .music, !sourceURL.isFileURL {
            importMusicFromMediaLibraryURL(sourceURL, preferredName: preferredName, destinationDirectory: destinationDirectory)
            return
        }

        let destinationURL = uniqueDestinationURL(
            in: destinationDirectory,
            preferredName: preferredName,
            fileExtension: sourceURL.pathExtension
        )

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            reload()
        } catch {
            msg("Error importando recurso de Espacio Calma:", error)
        }
    }

    private func importMusicFromMediaLibraryURL(_ sourceURL: URL, preferredName: String, destinationDirectory: URL) {
        let destinationURL = uniqueDestinationURL(
            in: destinationDirectory,
            preferredName: preferredName,
            fileExtension: "m4a"
        )

        let asset = AVURLAsset(url: sourceURL)
        Task { [weak self] in
            guard let self else { return }
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                await MainActor.run {
                    msg("No se pudo crear sesión de exportación para la música seleccionada.")
                }
                return
            }

            do {
                try await exportSession.export(to: destinationURL, as: .m4a)
                await MainActor.run {
                    self.reload()
                }
            } catch {
                await MainActor.run {
                    msg("Error exportando música de Biblioteca:", error)
                }
            }
        }
    }

    private func deleteAsset(_ asset: CalmManagedAsset, kind: CalmManagedAssetKind) {
        let directory = assetsDirectory(for: kind)
        let url = directory.appendingPathComponent(asset.name)
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            reload()
        } catch {
            msg("Error eliminando recurso de Espacio Calma:", error)
        }
    }

    private func listAssets(kind: CalmManagedAssetKind) -> [CalmManagedAsset] {
        let directory = assetsDirectory(for: kind)
        let allowedExtensions: Set<String>

        switch kind {
        case .background:
            allowedExtensions = ["jpg", "jpeg", "png", "heic", "webp"]
        case .music:
            allowedExtensions = ["mp3", "m4a", "aac", "wav", "aif", "aiff", "caf"]
        }

        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
            .map { CalmManagedAsset(name: $0.lastPathComponent, url: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func ensureDirectories() {
        do {
            try fileManager.createDirectory(at: assetsDirectory(for: .background), withIntermediateDirectories: true)
            try fileManager.createDirectory(at: assetsDirectory(for: .music), withIntermediateDirectories: true)
        } catch {
            msg("Error creando carpetas de recursos de Espacio Calma:", error)
        }
    }

    private func uniqueDestinationURL(in directory: URL, preferredName: String, fileExtension: String) -> URL {
        let cleanedName = preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = cleanedName.isEmpty ? "recurso" : cleanedName
        let ext = fileExtension.isEmpty ? "dat" : fileExtension

        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension(ext)
        var index = 1
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(baseName)-\(index)")
                .appendingPathExtension(ext)
            index += 1
        }
        return candidate
    }

    private func rootDirectory() -> URL {
        let fallback = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fallback

        return appSupport.appendingPathComponent("EspacioCalma", isDirectory: true)
    }

    private func assetsDirectory(for kind: CalmManagedAssetKind) -> URL {
        switch kind {
        case .background:
            return rootDirectory().appendingPathComponent("Fondos", isDirectory: true)
        case .music:
            return rootDirectory().appendingPathComponent("Musica", isDirectory: true)
        }
    }
}

struct CalmResourcesManagerView: View {
    @StateObject private var store = CalmResourceStore()
    @StateObject private var audioPreview = CalmAudioPreviewController()
    @State private var selectedBackgroundPreview: CalmManagedAsset?

    @State private var showBackgroundPhotosPicker = false
    @State private var showFileImporter = false
    @State private var activeFileImportKind: CalmManagedAssetKind = .background

    @State private var selectedBackgroundPhotoItem: PhotosPickerItem?

    #if canImport(UIKit) && canImport(MediaPlayer)
    @State private var showMusicLibraryPicker = false
    @State private var showMusicImportError = false
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                backgroundListSection
                musicListSection
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
        .navigationTitle("Recursos Para Espacio Calma")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .photosPicker(
            isPresented: $showBackgroundPhotosPicker,
            selection: $selectedBackgroundPhotoItem,
            matching: .images
        )
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: activeFileImportKind == .background ? [.image] : [.audio],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            if activeFileImportKind == .background {
                store.importBackground(from: url)
            } else {
                store.importMusic(from: url)
            }
        }
        .onChange(of: selectedBackgroundPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                let ext = preferredImageExtension(from: newItem)
                let temporaryURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("calma_bg_\(UUID().uuidString).\(ext)")

                do {
                    try data.write(to: temporaryURL, options: .atomic)
                    store.importBackground(from: temporaryURL)
                } catch {
                    msg("Error guardando imagen temporal para fondo:", error)
                }
            }
        }
        #if canImport(UIKit) && canImport(MediaPlayer)
        .sheet(isPresented: $showMusicLibraryPicker) {
            CalmMusicLibraryPicker { pickedURL in
                Task { @MainActor in
                    showMusicLibraryPicker = false
                    guard let pickedURL else {
                        showMusicImportError = true
                        return
                    }
                    store.importMusic(from: pickedURL)
                }
            } onCancel: {
                Task { @MainActor in
                    showMusicLibraryPicker = false
                }
            }
        }
        .alert("No se pudo agregar esta música", isPresented: $showMusicImportError) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text("La canción seleccionada no se puede importar desde Biblioteca. Prueba con otra canción o usa Archivos internos.")
        }
        #endif
        .onDisappear {
            audioPreview.stop()
        }
#if os(macOS)
        .sheet(item: $selectedBackgroundPreview) { asset in
            CalmBackgroundPreviewView(asset: asset)
        }
#else
        .fullScreenCover(item: $selectedBackgroundPreview) { asset in
            CalmBackgroundPreviewView(asset: asset)
        }
#endif
    }

    private var backgroundListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Agregar Fondos")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                Button {
                    showBackgroundPhotosPicker = true
                } label: {
                    Label("Galería", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)

                Button {
                    activeFileImportKind = .background
                    DispatchQueue.main.async {
                        showFileImporter = true
                    }
                } label: {
                    Label("Archivos internos", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }

            List {
                if store.backgroundAssets.isEmpty {
                    Text("No has agregado fondos.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.backgroundAssets) { asset in
                        HStack {
                            Button {
                                selectedBackgroundPreview = asset
                            } label: {
                                backgroundThumbnail(for: asset)
                            }
                            .buttonStyle(.plain)
                            Text(asset.name)
                                .lineLimit(1)
                            Spacer()
                            Button(role: .destructive) {
                                store.deleteBackground(asset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .frame(minHeight: 260, maxHeight: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var musicListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Agregar Música")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                #if canImport(UIKit) && canImport(MediaPlayer)
                Button {
                    showMusicLibraryPicker = true
                } label: {
                    Label("Biblioteca", systemImage: "music.note.list")
                }
                .buttonStyle(.bordered)
                #endif

                Button {
                    activeFileImportKind = .music
                    DispatchQueue.main.async {
                        showFileImporter = true
                    }
                } label: {
                    Label("Archivos internos", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }

            List {
                if store.musicAssets.isEmpty {
                    Text("No has agregado música.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.musicAssets) { asset in
                        HStack {
                            Button {
                                audioPreview.togglePlayback(for: asset)
                            } label: {
                                Image(systemName: audioPreview.playingAssetID == asset.id ? "stop.fill" : "play.fill")
                                    .frame(width: 28, height: 28)
                                    .background(Color.black.opacity(0.08), in: Circle())
                            }
                            .buttonStyle(.plain)

                            Text(asset.name)
                                .lineLimit(1)
                            Spacer()
                            Button(role: .destructive) {
                                if audioPreview.playingAssetID == asset.id {
                                    audioPreview.stop()
                                }
                                store.deleteMusic(asset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .frame(minHeight: 180, maxHeight: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func preferredImageExtension(from item: PhotosPickerItem) -> String {
        if let type = item.supportedContentTypes.first {
            if type.conforms(to: .png) { return "png" }
            if type.conforms(to: .heic) || type.conforms(to: .heif) { return "heic" }
        }
        return "jpg"
    }

    @ViewBuilder
    private func backgroundThumbnail(for asset: CalmManagedAsset) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(contentsOfFile: asset.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
        } else {
            fallbackThumbnail
        }
        #elseif canImport(AppKit)
        if let image = NSImage(contentsOf: asset.url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
        } else {
            fallbackThumbnail
        }
        #else
        fallbackThumbnail
        #endif
    }

    private var fallbackThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            )
    }
}

private struct CalmBackgroundPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let asset: CalmManagedAsset

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            imageView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.5), in: Circle())
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }

    @ViewBuilder
    private var imageView: some View {
        #if canImport(UIKit)
        if let image = UIImage(contentsOfFile: asset.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            fallback
        }
        #elseif canImport(AppKit)
        if let image = NSImage(contentsOf: asset.url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    private var fallback: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.system(size: 34))
            Text("No se pudo cargar la imagen")
                .font(.footnote)
        }
        .foregroundStyle(.white.opacity(0.8))
    }
}

#if canImport(UIKit) && canImport(MediaPlayer)
private struct CalmMusicLibraryPicker: UIViewControllerRepresentable {
    let onPick: @Sendable (URL?) -> Void
    let onCancel: @Sendable () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.prompt = L10n.exact("Selecciona música")
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let onPick: @Sendable (URL?) -> Void
        let onCancel: @Sendable () -> Void

        init(onPick: @escaping @Sendable (URL?) -> Void, onCancel: @escaping @Sendable () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        nonisolated func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            let url = mediaItemCollection.items.first?.assetURL
            let onPick = self.onPick
            onPick(url)
        }

        nonisolated func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            let onCancel = self.onCancel
            onCancel()
        }
    }
}
#endif

#Preview {
    NavigationStack {
        CalmResourcesManagerView()
    }
}
