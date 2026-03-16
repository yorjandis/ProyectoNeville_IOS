//
//  ManagedAssetsSupportError.swift
//  Neville_iOS
//
//  Created by Codex on 15/03/26.
//

import Foundation

enum ManagedAssetsSupportError: LocalizedError {
    case featureUnavailable
    case appGroupContainerNotFound(String)

    var errorDescription: String? {
        switch self {
        case .featureUnavailable:
            return "Managed Background Assets no está disponible en esta versión del sistema."
        case .appGroupContainerNotFound(let appGroupID):
            return "No se encontró el contenedor del App Group: \(appGroupID)."
        }
    }
}
