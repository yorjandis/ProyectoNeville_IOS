//
//  BackgroundDownloadHandler.swift
//  BackgroundDownloadExtension
//
//  Created by Codex on 15/03/26.
//

#if BACKGROUND_DOWNLOAD_EXTENSION
import StoreKit
import BackgroundAssets

@main
struct BackgroundDownloadHandler: StoreDownloaderExtension {
    // Se filtran asset packs para descargar solo el paquete de SQLite.
    func shouldDownload(_ assetPack: AssetPack) -> Bool {
        assetPack.id == "openfoodfacts-compact-db"
    }
}
#endif
