import Foundation

struct CardioCoherenceCustomMusicStore {
    static func customMusicDirectory() -> URL {
        let fileManager = FileManager.default
        let fallback = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fallback
        return appSupport.appendingPathComponent("CoherenciaCardioCerebral", isDirectory: true)
            .appendingPathComponent("MusicaSesion", isDirectory: true)
    }

    static func ensureDirectory() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: customMusicDirectory(), withIntermediateDirectories: true)
    }

    static func currentCustomMusicURL() -> URL? {
        let fileManager = FileManager.default
        guard let fileName = UserDefaults.standard.string(forKey: CardioCoherenceConstants.Audio.customMusicFileNameKey), !fileName.isEmpty else {
            return nil
        }
        let url = customMusicDirectory().appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func replaceMusic(with sourceURL: URL) throws {
        let fileManager = FileManager.default
        try ensureDirectory()

        var didAccess = false
        if sourceURL.startAccessingSecurityScopedResource() {
            didAccess = true
        }
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let directory = customMusicDirectory()
        if let existingURL = currentCustomMusicURL(), fileManager.fileExists(atPath: existingURL.path) {
            try? fileManager.removeItem(at: existingURL)
        }

        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destinationName = "coherencia_personal.\(ext.lowercased())"
        let destinationURL = directory.appendingPathComponent(destinationName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        UserDefaults.standard.set(destinationName, forKey: CardioCoherenceConstants.Audio.customMusicFileNameKey)
    }

    static func clearMusic() {
        let fileManager = FileManager.default
        if let existingURL = currentCustomMusicURL(), fileManager.fileExists(atPath: existingURL.path) {
            try? fileManager.removeItem(at: existingURL)
        }
        UserDefaults.standard.removeObject(forKey: CardioCoherenceConstants.Audio.customMusicFileNameKey)
        UserDefaults.standard.set(false, forKey: CardioCoherenceConstants.Audio.useCustomMusicInSessionKey)
    }
}
