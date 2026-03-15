//
//  LectorEtiquetasProtocols.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation
import CoreGraphics

@MainActor
protocol EtiquetaTextRecognizing {
    func recognizeText(from image: CGImage) async throws -> String
}

@MainActor
protocol EtiquetaParsing {
    func parse(text: String) -> EtiquetaParseResult
}

@MainActor
protocol EtiquetaRiskEvaluating {
    func evaluate(parseResult: EtiquetaParseResult) -> [HallazgoRiesgoEtiqueta]
}
