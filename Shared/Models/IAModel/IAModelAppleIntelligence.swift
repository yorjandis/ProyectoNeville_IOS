//
//  IAModelAppleIntelligence.swift
//  Neville_iOS
//
//  Operaciones de análisis con el modelo local de Apple.
//

import Combine
import Foundation
import FoundationModels
import SwiftUI

@MainActor
@available(iOS 26.0, macOS 26.0, *)
final class IAModelAppleIntelligence: ObservableObject {
    @Published var puntosClaves: [String] = []
    @Published var resumenGeneral = ""
    @Published var practicas: [String] = []
    @Published var practicaConcreta = ""
    @Published var interpretacion = ""
    @Published var noFragmentos = 0
    @Published var fragmentoActual = 0

    let maxLengthContext = 4_000

    func executeRequestPuntosClaves(texto: String) async throws {
        let fragments = try preparedFragments(from: texto)
        puntosClaves.removeAll()
        beginProgress(total: fragments.count)
        defer { endProgress() }

        var collected: [String] = []
        for (index, fragment) in fragments.enumerated() {
            try Task.checkCancellation()
            fragmentoActual = index + 1
            let session = LanguageModelSession(instructions: """
                Extrae las ideas esenciales del texto proporcionado.
                Sé fiel al contenido, no añadas información y redacta cada idea como una oración completa.
                \(AppLanguage.current.aiResponseInstruction)
                """)
            let result = try await session.respond(
                to: fragment,
                generating: Summary.self,
                options: GenerationOptions(maximumResponseTokens: 420)
            ).content
            collected.append(contentsOf: result.keyPoints)
        }

        puntosClaves = try await consolidateKeyPoints(collected)
    }

    func executeRequestResumenGeneral(texto: String) async throws {
        let fragments = try preparedFragments(from: texto)
        resumenGeneral = ""
        beginProgress(total: fragments.count)
        defer { endProgress() }

        var partialSummaries: [String] = []
        for (index, fragment) in fragments.enumerated() {
            try Task.checkCancellation()
            fragmentoActual = index + 1
            partialSummaries.append(try await summarizeText(fragment))
        }

        let reduced = try await reduceSummaries(partialSummaries)
        let finalSession = LanguageModelSession(instructions: """
            Redacta un resumen general claro, coherente, detallado y fiel al material.
            No añadas opiniones ni información externa.
            \(AppLanguage.current.aiResponseInstruction)
            """)
        resumenGeneral = try await finalSession.respond(
            to: reduced,
            generating: ResumenG.self,
            options: GenerationOptions(maximumResponseTokens: 650)
        ).content.resumen
    }

    func executeRequestListAplicacionPractica(
        texto: String,
        autor: String = "nev"
    ) async throws {
        let fragments = try preparedFragments(from: texto)
        practicas.removeAll()
        beginProgress(total: fragments.count)
        defer { endProgress() }

        var partialSummaries: [String] = []
        for (index, fragment) in fragments.enumerated() {
            try Task.checkCancellation()
            fragmentoActual = index + 1
            partialSummaries.append(try await summarizeText(fragment))
        }
        let reduced = try await reduceSummaries(partialSummaries)

        let author = Autores(storedRawValue: autor)
        let session = LanguageModelSession(instructions: """
            Interpreta el material únicamente desde este marco:
            \(InstructionIA.principles(for: author))

            Genera acciones concretas derivadas del material.
            No menciones el marco, no añadas información externa y no presentes resultados como garantizados.
            Mantén cada acción breve, segura y aplicable.
            \(AppLanguage.current.aiResponseInstruction)
            """)
        practicas = try await session.respond(
            to: reduced,
            generating: PracticalAdvice.self,
            options: GenerationOptions(maximumResponseTokens: 520)
        ).content.actionableSteps
    }

    func executeRequestPracticaConcreta(
        texto: String,
        autor: String = "nev"
    ) async throws {
        let cleanText = try validate(texto)
        practicaConcreta = ""
        try ensureModelAvailability()
        let author = Autores(storedRawValue: autor)
        let session = LanguageModelSession(instructions: """
            Interpreta el texto únicamente desde este marco:
            \(InstructionIA.principles(for: author))

            Propón una única aplicación práctica precisa, segura y realista.
            No menciones el marco, no añadas ideas externas y no excedas 180 palabras.
            No presentes resultados como garantizados ni sustituyas ayuda profesional.
            \(AppLanguage.current.aiResponseInstruction)
            """)
        practicaConcreta = try await session.respond(
            to: cleanText,
            options: GenerationOptions(maximumResponseTokens: 300)
        ).content
    }

    func executeRequestInterpretaTexto(
        texto: String,
        autor: String = "nev"
    ) async throws {
        let cleanText = try validate(texto)
        interpretacion = ""
        try ensureModelAvailability()
        let author = Autores(storedRawValue: autor)
        let session = LanguageModelSession(instructions: """
            Interpreta el texto únicamente desde este marco:
            \(InstructionIA.principles(for: author))

            Explica su sentido con claridad y fidelidad.
            No menciones el marco, no añadas información externa y no excedas 220 palabras.
            Distingue enseñanzas o creencias de hechos científicos y no sustituyas ayuda profesional.
            \(AppLanguage.current.aiResponseInstruction)
            """)
        interpretacion = try await session.respond(
            to: cleanText,
            options: GenerationOptions(maximumResponseTokens: 360)
        ).content
    }

    private func preparedFragments(from text: String) throws -> [String] {
        try ensureModelAvailability()
        let cleanText = try validate(text)
        let fragments = Self.dividirTexto(cleanText, maxLength: maxLengthContext)
        guard !fragments.isEmpty else { throw AIProcessingError.emptyText }
        return fragments
    }

    private func validate(_ text: String) throws -> String {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { throw AIProcessingError.emptyText }
        return cleanText
    }

    private func ensureModelAvailability() throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIProcessingError.modelUnavailable
        }
    }

    private func beginProgress(total: Int) {
        noFragmentos = total
        fragmentoActual = 0
    }

    private func endProgress() {
        noFragmentos = 0
        fragmentoActual = 0
    }

    private func summarizeText(_ text: String) async throws -> String {
        let session = LanguageModelSession(instructions: """
            Resume el texto con fidelidad y lenguaje sencillo.
            Conserva las ideas necesarias para poder elaborar después un resumen global.
            No añadas opiniones ni información externa.
            Devuelve menos de 220 palabras.
            \(AppLanguage.current.aiResponseInstruction)
            """)
        return try await session.respond(
            to: text,
            options: GenerationOptions(maximumResponseTokens: 330)
        ).content
    }

    private func reduceSummaries(_ initialSummaries: [String]) async throws -> String {
        guard !initialSummaries.isEmpty else { throw AIProcessingError.emptyResult }
        var summaries = initialSummaries

        while summaries.count > 1 {
            try Task.checkCancellation()
            let batches = Self.pack(
                summaries,
                maximumCharacters: maxLengthContext
            )
            var nextLevel: [String] = []
            for batch in batches {
                try Task.checkCancellation()
                nextLevel.append(try await summarizeText(batch))
            }
            if nextLevel == summaries {
                break
            }
            summaries = nextLevel
        }
        return summaries.joined(separator: "\n\n")
    }

    private func consolidateKeyPoints(_ values: [String]) async throws -> [String] {
        var points = Self.deduplicated(values)
        guard !points.isEmpty else { throw AIProcessingError.emptyResult }

        while points.count > 10 || points.joined(separator: "\n").count > maxLengthContext {
            try Task.checkCancellation()
            let batches = Self.pack(points, maximumCharacters: maxLengthContext)
            var reduced: [String] = []
            for batch in batches {
                let session = LanguageModelSession(instructions: """
                    Consolida ideas relacionadas y elimina duplicados.
                    Conserva solo los puntos esenciales presentes en el contenido.
                    No añadas información y redacta oraciones completas.
                    \(AppLanguage.current.aiResponseInstruction)
                    """)
                let response = try await session.respond(
                    to: batch,
                    generating: Summary.self,
                    options: GenerationOptions(maximumResponseTokens: 420)
                ).content
                reduced.append(contentsOf: response.keyPoints)
            }
            let deduplicated = Self.deduplicated(reduced)
            if deduplicated == points {
                points = Array(points.prefix(10))
                break
            }
            points = deduplicated
        }
        return Array(points.prefix(10))
    }

    static func dividirTexto(_ texto: String, maxLength: Int) -> [String] {
        guard maxLength > 0 else { return [] }
        let normalized = texto
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        var fragments: [String] = []
        var start = normalized.startIndex

        while start < normalized.endIndex {
            let tentativeEnd = normalized.index(
                start,
                offsetBy: maxLength,
                limitedBy: normalized.endIndex
            ) ?? normalized.endIndex
            var end = tentativeEnd

            if tentativeEnd < normalized.endIndex {
                let candidate = normalized[start..<tentativeEnd]
                let minimumDistance = maxLength / 2
                let separators = ["\n\n", "\n", ". ", "; ", ", ", " "]
                for separator in separators {
                    guard let range = candidate.range(of: separator, options: .backwards) else {
                        continue
                    }
                    let distance = normalized.distance(from: start, to: range.upperBound)
                    if distance >= minimumDistance {
                        end = range.upperBound
                        break
                    }
                }
            }

            let fragment = normalized[start..<end]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !fragment.isEmpty {
                fragments.append(fragment)
            }
            start = end
        }
        return fragments
    }

    private static func pack(
        _ strings: [String],
        maximumCharacters: Int
    ) -> [String] {
        var batches: [String] = []
        var current = ""

        for value in strings {
            let chunks = dividirTexto(value, maxLength: maximumCharacters)
            for chunk in chunks {
                if current.count + chunk.count + 2 > maximumCharacters {
                    if !current.isEmpty {
                        batches.append(current)
                    }
                    current = chunk
                } else {
                    current += current.isEmpty ? chunk : "\n\n\(chunk)"
                }
            }
        }
        if !current.isEmpty {
            batches.append(current)
        }
        return batches
    }

    private static func deduplicated(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.compactMap { value in
            let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return nil }
            let key = clean.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            return seen.insert(key).inserted ? clean : nil
        }
    }

    static func isAvailable() -> Bool {
        SystemLanguageModel.default.isAvailable
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Resumen estructurado de las ideas esenciales de un texto.")
struct Summary {
    @Guide(
        description: "Ideas esenciales, completas, sin repeticiones.",
        .minimumCount(1),
        .maximumCount(10)
    )
    let keyPoints: [String]
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Resumen general, claro y conciso de un contenido.")
struct ResumenG {
    @Guide(description: "Resumen fiel al contenido.")
    let resumen: String
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Acciones prácticas derivadas de un contenido.")
struct PracticalAdvice {
    @Guide(
        description: "Acciones concretas, breves, seguras y sin repeticiones.",
        .minimumCount(1),
        .maximumCount(8)
    )
    let actionableSteps: [String]
}

enum TiposSalida {
    case puntosClaves
    case resumen
    case practicas
    case practicaConcreta
    case interpretar
}

enum AIProcessingError: LocalizedError {
    case emptyText
    case emptyResult
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "No hay texto para procesar."
        case .emptyResult:
            return "El modelo no pudo obtener un resultado útil."
        case .modelUnavailable:
            return "Apple Intelligence no está disponible en este dispositivo."
        }
    }
}

@ViewBuilder
func CreateViewIfAppleIntelligence<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    if #available(iOS 26.0, macOS 26.0, *) {
        if SystemLanguageModel.default.isAvailable {
            content()
        } else {
            ContentUnavailableView(
                "Apple Intelligence no disponible",
                systemImage: "sparkles",
                description: Text(
                    "Comprueba que el dispositivo sea compatible, Apple Intelligence esté activado y el modelo termine de descargarse."
                )
            )
        }
    } else {
        ContentUnavailableView(
            "Sistema no compatible",
            systemImage: "sparkles",
            description: Text("Esta función requiere iOS 26 o macOS 26.")
        )
    }
}
