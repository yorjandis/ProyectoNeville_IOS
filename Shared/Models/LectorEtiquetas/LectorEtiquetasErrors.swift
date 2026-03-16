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
            return "No se detectó texto para analizar."
        case .codigoBarrasInvalido:
            return "El código de barras no es válido."
        case .productoNoEncontradoEnOpenFoodFacts:
            return "No se encontró el producto en OpenFoodFacts para ese código."
        case .respuestaOpenFoodFactsInvalida:
            return "La respuesta de OpenFoodFacts no se pudo procesar."
        case .redOpenFoodFacts(let error):
            return "Error de red con OpenFoodFacts: \(error.localizedDescription)"
        case .reconocimientoNoDisponible:
            return "El reconocimiento de texto no está disponible en este dispositivo."
        case .ocrSinResultados:
            return "No fue posible extraer texto legible de la etiqueta."
        case .ocrFallido(let error):
            return "Error de OCR: \(error.localizedDescription)"
        case .baseOfflineNoDisponible:
            return "La base de datos offline no está disponible todavía. Descárgala y verifícala."
        case .productoNoEncontradoEnBaseOffline:
            return "No se encontró el producto en la base de datos offline para ese código."
        }
    }
}
