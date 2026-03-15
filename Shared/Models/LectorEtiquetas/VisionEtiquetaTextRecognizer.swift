//
//  VisionEtiquetaTextRecognizer.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation
import CoreGraphics

#if canImport(Vision)
@preconcurrency import Vision

final class VisionEtiquetaTextRecognizer: EtiquetaTextRecognizing {
    func recognizeText(from image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: LectorEtiquetasError.ocrFallido(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: LectorEtiquetasError.ocrSinResultados)
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let joinedText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

                guard !joinedText.isEmpty else {
                    continuation.resume(throwing: LectorEtiquetasError.ocrSinResultados)
                    return
                }

                continuation.resume(returning: joinedText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["es-ES", "es-MX", "en-US"]

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: LectorEtiquetasError.ocrFallido(error))
            }
        }
    }
}
#else
final class VisionEtiquetaTextRecognizer: EtiquetaTextRecognizing {
    func recognizeText(from image: CGImage) async throws -> String {
        throw LectorEtiquetasError.reconocimientoNoDisponible
    }
}
#endif
