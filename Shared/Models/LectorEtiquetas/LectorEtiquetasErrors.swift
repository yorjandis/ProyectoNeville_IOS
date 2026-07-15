//
//  LectorEtiquetasErrors.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

enum LectorEtiquetasError: Error, LocalizedError {
    case textoVacio
    case codigoBarrasInvalido
    case productoNoEncontradoEnOpenFoodFacts
    case respuestaOpenFoodFactsInvalida
    case redOpenFoodFacts(Error)
    case reconocimientoNoDisponible
    case ocrSinResultados
    case ocrFallido(Error)
    case baseOfflineNoDisponible
    case productoNoEncontradoEnBaseOffline

    var errorDescription: String? {
        switch self {
        case .textoVacio:
            return L10n.exact("No se detectó texto para analizar.")
        case .codigoBarrasInvalido:
            return L10n.exact("El código de barras no es válido.")
        case .productoNoEncontradoEnOpenFoodFacts:
            return L10n.exact("No se encontró el producto en OpenFoodFacts para ese código.")
        case .respuestaOpenFoodFactsInvalida:
            return L10n.exact("La respuesta de OpenFoodFacts no se pudo procesar.")
        case .redOpenFoodFacts(let error):
            return L10n.format(
                "label_reader.error.openfoodfacts_network",
                fallback: "Error de red con OpenFoodFacts: {0}",
                error.localizedDescription
            )
        case .reconocimientoNoDisponible:
            return L10n.exact("El reconocimiento de texto no está disponible en este dispositivo.")
        case .ocrSinResultados:
            return L10n.exact("No fue posible extraer texto legible de la etiqueta.")
        case .ocrFallido(let error):
            return L10n.format(
                "label_reader.error.ocr",
                fallback: "Error de OCR: {0}",
                error.localizedDescription
            )
        case .baseOfflineNoDisponible:
            return L10n.exact("La base de datos offline no está disponible todavía. Descárgala y verifícala.")
        case .productoNoEncontradoEnBaseOffline:
            return L10n.exact("No se encontró el producto en la base de datos offline para ese código.")
        }
    }
}
