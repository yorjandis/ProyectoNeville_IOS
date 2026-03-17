//
//  LectorEtiquetasManagedAssetsConfig.swift
//  Neville_iOS
//
//  Created by Codex on 15/03/26.
//

import Foundation

enum LectorEtiquetasManagedAssetsConfig {
    nonisolated static let appGroupID = "group.com.ypg.nev.group"
    nonisolated static let assetPackID = "openfoodfacts-compact-db"

    // Ruta relativa dentro del asset pack.
    nonisolated static let sqliteRelativePath = "database/openfoodfacts_compact.sqlite"
    nonisolated static let sqliteFileName = "openfoodfacts_compact.sqlite"

    nonisolated static let versionDefaultsKey = "managed_assets.openfoodfacts.version"
    nonisolated static let databasePathDefaultsKey = "managed_assets.openfoodfacts.database_path"
}
