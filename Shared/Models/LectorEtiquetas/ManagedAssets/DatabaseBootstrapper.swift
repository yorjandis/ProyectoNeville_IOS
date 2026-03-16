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

    func bootstrapDatabase() async throws -> Result {
        guard #available(iOS 26.0, *) else {
            throw ManagedAssetsSupportError.featureUnavailable
        }
        return try await bootstrapDatabase_iOS26()
    }

    @available(iOS 26.0, *)
    private func bootstrapDatabase_iOS26() async throws -> Result {
        let manager = AssetPackManager.shared
        let assetPack = try await manager.assetPack(withID: LectorEtiquetasManagedAssetsConfig.assetPackID)
        try await manager.ensureLocalAvailability(of: assetPack)

        let sourceURL = try manager.url(for: FilePath(LectorEtiquetasManagedAssetsConfig.sqliteRelativePath))
        let destinationURL = try makeDestinationDatabaseURL()

        let defaults = UserDefaults(suiteName: LectorEtiquetasManagedAssetsConfig.appGroupID)
        let currentVersion = defaults?.integer(forKey: LectorEtiquetasManagedAssetsConfig.versionDefaultsKey)

        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: destinationURL.path)
        let needsCopy = !fileExists || currentVersion != assetPack.version

        if needsCopy {
            if fileExists {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            defaults?.set(assetPack.version, forKey: LectorEtiquetasManagedAssetsConfig.versionDefaultsKey)
        }

        return Result(databaseURL: destinationURL, didCopy: needsCopy, installedVersion: assetPack.version)
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

    func bootstrapDatabase() async throws -> Result {
        throw ManagedAssetsSupportError.featureUnavailable
    }
}
#endif
