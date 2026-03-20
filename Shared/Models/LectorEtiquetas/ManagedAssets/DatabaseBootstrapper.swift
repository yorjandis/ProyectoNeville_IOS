//
//  DatabaseBootstrapper.swift
//  Neville_iOS
//
//  Created by Codex on 15/03/26.
//

import Foundation

#if os(iOS) && canImport(BackgroundAssets)
import BackgroundAssets
import System

actor DatabaseBootstrapper {
    struct Result {
        let databaseURL: URL
        let didCopy: Bool
        let installedVersion: Int
    }

    struct UpdateStatus {
        let latestVersion: Int
        let installedVersion: Int?
        let hasUpdate: Bool
    }

    func bootstrapDatabase(forceCopy: Bool = false) async throws -> Result {
        guard #available(iOS 26.0, *) else {
            throw ManagedAssetsSupportError.featureUnavailable
        }
        return try await bootstrapDatabase_iOS26(forceCopy: forceCopy)
    }

    func checkForAvailableUpdate() async throws -> UpdateStatus {
        guard #available(iOS 26.0, *) else {
            throw ManagedAssetsSupportError.featureUnavailable
        }
        return try await checkForAvailableUpdate_iOS26()
    }

    @available(iOS 26.0, *)
    private func bootstrapDatabase_iOS26(forceCopy: Bool) async throws -> Result {
        let manager = AssetPackManager.shared
        let assetPack = try await manager.assetPack(withID: LectorEtiquetasManagedAssetsConfig.assetPackID)
        try await manager.ensureLocalAvailability(of: assetPack)

        let sourceURL = try resolveSQLiteURL(manager: manager)
        let destinationURL = try makeDestinationDatabaseURL()

        let defaults = UserDefaults(suiteName: LectorEtiquetasManagedAssetsConfig.appGroupID)
        let currentVersion = defaults?.integer(forKey: LectorEtiquetasManagedAssetsConfig.versionDefaultsKey)

        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: destinationURL.path)
        let needsCopy = forceCopy || !fileExists || currentVersion != assetPack.version

        if needsCopy {
            if fileExists {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            defaults?.set(assetPack.version, forKey: LectorEtiquetasManagedAssetsConfig.versionDefaultsKey)
        }

        return Result(databaseURL: destinationURL, didCopy: needsCopy, installedVersion: assetPack.version)
    }

    @available(iOS 26.0, *)
    private func checkForAvailableUpdate_iOS26() async throws -> UpdateStatus {
        let manager = AssetPackManager.shared
        let assetPack = try await manager.assetPack(withID: LectorEtiquetasManagedAssetsConfig.assetPackID)
        let defaults = UserDefaults(suiteName: LectorEtiquetasManagedAssetsConfig.appGroupID)
        let installedVersion = (defaults?.object(forKey: LectorEtiquetasManagedAssetsConfig.versionDefaultsKey) as? NSNumber)?.intValue
        let destinationURL = try makeDestinationDatabaseURL()
        let hasLocalDatabase = FileManager.default.fileExists(atPath: destinationURL.path)
        let hasUpdate = hasLocalDatabase && ((installedVersion ?? assetPack.version) < assetPack.version)

        return UpdateStatus(
            latestVersion: assetPack.version,
            installedVersion: installedVersion,
            hasUpdate: hasUpdate
        )
    }

    @available(iOS 26.0, *)
    private func resolveSQLiteURL(manager: AssetPackManager) throws -> URL {
        let fileManager = FileManager.default
        let configuredPath = LectorEtiquetasManagedAssetsConfig.sqliteRelativePath
        let sqliteFileName = LectorEtiquetasManagedAssetsConfig.sqliteFileName
        let baseDirectory = (configuredPath as NSString).deletingLastPathComponent
        let assetPackID = LectorEtiquetasManagedAssetsConfig.assetPackID

        let pathCandidates = [
            configuredPath,
            sqliteFileName,
            "\(assetPackID)/\(configuredPath)",
            "asset-pack/\(assetPackID)/\(configuredPath)"
        ]

        for candidatePath in pathCandidates {
            if let candidateURL = try? manager.url(for: FilePath(candidatePath)),
               fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        // Variantes donde url(for:) devuelve carpeta y hay que anexar el archivo.
        var directoryURLs: [URL] = []
        let directoryCandidates = [
            baseDirectory,
            assetPackID,
            "\(assetPackID)/\(baseDirectory)",
            "asset-pack/\(assetPackID)",
            "asset-pack/\(assetPackID)/\(baseDirectory)"
        ]

        for directoryPath in directoryCandidates where !directoryPath.isEmpty {
            if let directoryURL = try? manager.url(for: FilePath(directoryPath)) {
                let candidate = directoryURL.appendingPathComponent(sqliteFileName, isDirectory: false)
                if fileManager.fileExists(atPath: candidate.path) {
                    return candidate
                }
                directoryURLs.append(directoryURL)
            }
        }

        // Último fallback: buscar recursivamente por nombre de archivo.
        for directoryURL in directoryURLs {
            if let enumerator = fileManager.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    if fileURL.lastPathComponent == sqliteFileName {
                        return fileURL
                    }
                }
            }
        }

        throw CocoaError(.fileNoSuchFile, userInfo: [
            NSFilePathErrorKey: configuredPath,
            NSLocalizedDescriptionKey: "No se encontró la SQLite del asset pack. Ruta configurada: \(configuredPath)."
        ])
    }

    private func makeDestinationDatabaseURL() throws -> URL {
        let fileManager = FileManager.default

        guard let groupContainer = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: LectorEtiquetasManagedAssetsConfig.appGroupID
        ) else {
            throw ManagedAssetsSupportError.appGroupContainerNotFound(LectorEtiquetasManagedAssetsConfig.appGroupID)
        }

        let appSupport = groupContainer
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("LectorEtiquetas", isDirectory: true)

        try fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)

        return appSupport.appendingPathComponent(LectorEtiquetasManagedAssetsConfig.sqliteFileName)
    }
}
#else
actor DatabaseBootstrapper {
    struct Result {
        let databaseURL: URL
        let didCopy: Bool
        let installedVersion: Int
    }

    struct UpdateStatus {
        let latestVersion: Int
        let installedVersion: Int?
        let hasUpdate: Bool
    }

    func bootstrapDatabase(forceCopy: Bool = false) async throws -> Result {
        throw ManagedAssetsSupportError.featureUnavailable
    }

    func checkForAvailableUpdate() async throws -> UpdateStatus {
        throw ManagedAssetsSupportError.featureUnavailable
    }
}
#endif
