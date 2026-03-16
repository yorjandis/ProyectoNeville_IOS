//
//  BackgroundDownloadHandler.swift
//  LaLeyBackgroundDownloadExtension
//
//  Created by Yorjandis PG on 15/3/26.
//

import BackgroundAssets
import ExtensionFoundation
import StoreKit

@main
struct DownloaderExtension: StoreDownloaderExtension {
    func shouldDownload(_ assetPack: AssetPack) -> Bool {
        assetPack.id == "openfoodfacts-compact-db"
    }
}
