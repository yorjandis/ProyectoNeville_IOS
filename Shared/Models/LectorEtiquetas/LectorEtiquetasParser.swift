//
//  LectorEtiquetasParser.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

struct DefaultEtiquetaParser: EtiquetaParsing {
    func parse(text: String) -> EtiquetaParseResult {
        let cleanedText = normalizeBreaklines(text)
        let lines = cleanedText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let base = detectMeasurementBase(in: cleanedText)
        let columnHint = detectColumnHint(lines: lines)

        return EtiquetaParseResult(
            originalText: cleanedText,
            ingredientes: extractIngredients(from: lines),
            nutrientes: extractNutrients(from: lines, defaultBase: base, columnHint: columnHint),
            baseDetectada: base
        )
    }

    private func normalizeBreaklines(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func detectMeasurementBase(in text: String) -> BaseMedicionEtiqueta {
        let normalized = normalize(text)

        if normalized.contains("por 100") || normalized.contains("/100") || normalized.contains("per 100") {
            return .por100g
        }

        if normalized.contains("por porcion") || normalized.contains("porcion") || normalized.contains("porcion") || normalized.contains("per serving") {
            return .porPorcion
        }

        return .desconocida
    }

    private func detectColumnHint(lines: [String]) -> (BaseMedicionEtiqueta, BaseMedicionEtiqueta)? {
        for line in lines {
            let normalized = normalize(line)
            let containsServing = normalized.contains("porcion") || normalized.contains("serving")
            let contains100 = normalized.contains("100 g") || normalized.contains("100g") || normalized.contains("100 ml") || normalized.contains("100ml") || normalized.contains("per 100")

            guard containsServing && contains100 else { continue }

            let servingIndex = normalized.range(of: "porcion")?.lowerBound ?? normalized.range(of: "serving")?.lowerBound
            let hundredIndex = normalized.range(of: "100")?.lowerBound

            if let servingIndex, let hundredIndex {
                if servingIndex < hundredIndex {
                    return (.porPorcion, .por100g)
                }
                return (.por100g, .porPorcion)
            }
        }

        return nil
    }

    private func extractIngredients(from lines: [String]) -> [String] {
        var buffer: [String] = []
        var readingIngredients = false

        for line in lines {
            let normalized = normalize(line)

            if !readingIngredients {
                guard normalized.contains("ingredientes") || normalized.contains("ingredients") else {
                    continue
                }

                readingIngredients = true
                if let idx = line.firstIndex(of: ":") {
                    let nextIndex = line.index(after: idx)
                    let content = String(line[nextIndex...]).trimmingCharacters(in: .whitespaces)
                    if !content.isEmpty {
                        buffer.append(content)
                    }
                }
                continue
            }

            // Detener cuando comienza otra sección típica de etiqueta
            let startsAnotherSection = normalized.contains("informacion nutricional") ||
                normalized.contains("nutritional information") ||
                normalized.contains("tabla nutricional") ||
                normalized.contains("valor energetico") ||
                normalized.contains("modo de empleo") ||
                normalized.contains("conservacion")

            if startsAnotherSection {
                break
            }

            buffer.append(line)
        }

        guard !buffer.isEmpty else { return [] }

        let raw = buffer.joined(separator: ",")

        return raw
            .components(separatedBy: CharacterSet(charactersIn: ",;."))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func extractNutrients(
        from lines: [String],
        defaultBase: BaseMedicionEtiqueta,
        columnHint: (BaseMedicionEtiqueta, BaseMedicionEtiqueta)?
    ) -> [NutrienteEtiqueta] {
        var result: [NutrienteEtiqueta] = []

        for line in lines {
            guard let nutrientName = nutrientName(for: line) else { continue }

            let values = extractNumericValues(in: line)
            guard !values.isEmpty else { continue }

            if values.count >= 2, let columnHint {
                result.append(
                    NutrienteEtiqueta(
                        nombre: nutrientName,
                        valor: values[0].value,
                        unidad: values[0].unit,
                        base: columnHint.0
                    )
                )
                result.append(
                    NutrienteEtiqueta(
                        nombre: nutrientName,
                        valor: values[1].value,
                        unidad: values[1].unit,
                        base: columnHint.1
                    )
                )
            } else {
                let lineBase = detectMeasurementBase(in: line)
                let resolvedBase = lineBase == .desconocida ? defaultBase : lineBase

                result.append(
                    NutrienteEtiqueta(
                        nombre: nutrientName,
                        valor: values[0].value,
                        unidad: values[0].unit,
                        base: resolvedBase
                    )
                )
            }
        }

        return deduplicatedNutrients(result)
    }

    private func nutrientName(for line: String) -> String? {
        let normalized = normalize(line)

        if normalized.contains("azucar") || normalized.contains("sugar") {
            return "azucar"
        }

        if normalized.contains("grasa saturada") || normalized.contains("grasas saturadas") || normalized.contains("saturated fat") {
            return "grasa_saturada"
        }

        if normalized.contains("sodio") || normalized.contains("sodium") {
            return "sodio"
        }

        if normalized.contains("sal") || normalized.contains("salt") {
            return "sal"
        }

        return nil
    }

    private func extractNumericValues(in text: String) -> [(value: Double, unit: UnidadNutrienteEtiqueta)] {
        let pattern = "(?i)(\\d+(?:[\\.,]\\d+)?)\\s*(mg|g)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        var values: [(Double, UnidadNutrienteEtiqueta)] = []

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let valueRange = Range(match.range(at: 1), in: text),
                  let unitRange = Range(match.range(at: 2), in: text) else {
                continue
            }

            let rawValue = text[valueRange].replacingOccurrences(of: ",", with: ".")
            guard let parsedValue = Double(rawValue) else { continue }

            let unitText = text[unitRange].lowercased()
            let unidad: UnidadNutrienteEtiqueta = unitText == "mg" ? .mg : .g
            values.append((parsedValue, unidad))
        }

        return values
    }

    private func deduplicatedNutrients(_ nutrients: [NutrienteEtiqueta]) -> [NutrienteEtiqueta] {
        var map: [String: NutrienteEtiqueta] = [:]

        for nutrient in nutrients {
            let key = "\(nutrient.nombre)-\(nutrient.base.rawValue)"
            if let existing = map[key] {
                if nutrientInGrams(nutrient) > nutrientInGrams(existing) {
                    map[key] = nutrient
                }
            } else {
                map[key] = nutrient
            }
        }

        return Array(map.values)
    }

    private func nutrientInGrams(_ nutrient: NutrienteEtiqueta) -> Double {
        switch nutrient.unidad {
        case .g:
            return nutrient.valor
        case .mg:
            return nutrient.valor / 1_000
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
