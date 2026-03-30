/*
 Cambios principales:

 • Nuevo módulo independiente de scoring:
 LectorEtiquetasFoodRiskScoring.swift
 • Entrada desacoplada: LectorEtiquetasFoodRiskScoring.swift:7
 • Configuración editable (pesos/umbrales para futuro): LectorEtiquetasFoodRiskScoring.swift:38
 • Motor de cálculo 0...100 + clasificación Excelente​/​Bueno​/​Malo: LectorEtiquetasFoodRiskScoring.swift:88

 • Criterios incluidos en el algoritmo:
    • Presencia, tipo y cantidad de aditivos.
    • Orgánico / evidencia ecológica.
    • Gluten.
    • Exceso de azúcar, sal y grasas saturadas.
    • Fibra baja/media/alta.
    • Penalización por criterios sin datos (missing data).

 • Publicación en header​Section:
    • Se calcula por alimento y se muestra badge "​Riesgo propio: ​XX​/100 · ​Excelente​/​Bueno​/​Malo" en
 [LectorEtiquetasView.swift:299](/Users/yorjandis/Desktop/ProyectoNeville_IOS/Shared/Views/LectorEtiquetas/LectorEtiquetasView.swift:299) y [LectorEtiquetasView.swift:331](/Users/yorjandis/Desktop/ProyectoNeville_IOS/Shared/Views/LectorEtiquetas/LectorEtiquetasView.swift:331)

 • Color del badge por clasificación en
 [LectorEtiquetasView.swift:793](/Users/yorjandis/Desktop/ProyectoNeville_IOS/Shared/Views/LectorEtiquetas/LectorEtiquetasView.swift:793)
 */


import Foundation

protocol LectorEtiquetasFoodRiskScoring {
    func score(input: LectorEtiquetasFoodRiskScoringInput) -> LectorEtiquetasFoodRiskScoreResult
}

struct LectorEtiquetasFoodRiskScoringInput {
    let hallazgos: [HallazgoRiesgoEtiqueta]
    let perfilAlimentario: EtiquetaPerfilAlimentario
    let evaluacionEcologica: EtiquetaEvaluacionEcologica
    let nutrientesDetectados: [NutrienteEtiqueta]
    let nutrimentsFormatted: [OpenFoodFactsNutrimentItem]
    let alergenos: [String]
    let ingredientesDetectadosCount: Int
    let novaGroup: Int?
}

enum LectorEtiquetasFoodRiskClassification: String, Codable {
    case excelente
    case bueno
    case malo
    case informacionInsuficiente

    var title: String {
        switch self {
        case .excelente: return "Excelente"
        case .bueno: return "Bueno"
        case .malo: return "Malo"
        case .informacionInsuficiente: return "?"
        }
    }
}

struct LectorEtiquetasFoodRiskScoreResult {
    let score: Int
    let classification: LectorEtiquetasFoodRiskClassification
    let criteriosEvaluados: Int
    let criteriosSinDatos: Int
}

struct LectorEtiquetasFoodRiskScoringConfig {
    var additivePresencePenalty: Double = 6
    var additivePerItemPenalty: Double = 2
    var additivePerItemPenaltyCap: Double = 12
    var additiveSeverityPenaltyCap: Double = 24
    var noAdditivesBonus: Double = 4

    var organicTrueBonus: Double = 8
    var organicFalsePenalty: Double = 8
    var organicUnknownPenalty: Double = 2
    var ecologicalConfirmedBonus: Double = 5
    var ecologicalProbableBonus: Double = 2
    var ecologicalUnconfirmedPenalty: Double = 1

    var glutenPresentPenalty: Double = 18
    var glutenAbsentBonus: Double = 6
    var glutenUnknownPenalty: Double = 4

    var sugarPenaltyByLevel: [NivelRiesgoEtiqueta: Double] = [
        .medio: 8,
        .alto: 14,
        .critico: 20
    ]

    var saltPenaltyByLevel: [NivelRiesgoEtiqueta: Double] = [
        .medio: 7,
        .alto: 12,
        .critico: 18
    ]

    var saturatedFatPenaltyByLevel: [NivelRiesgoEtiqueta: Double] = [
        .medio: 6,
        .alto: 10,
        .critico: 16
    ]

    var lowSugarBonus: Double = 2
    var lowSaltBonus: Double = 2
    var lowSaturatedFatBonus: Double = 2

    var lowFiberPenalty: Double = 8
    var highFiberBonus: Double = 6

    var missingCriterionPenalty: Double = 2.5
    var maxMissingPenalty: Double = 10

    var excelenteMinScore: Int = 80
    var buenoMinScore: Int = 55
    var insufficientInfoLowScore: Int = 25

    static let `default` = LectorEtiquetasFoodRiskScoringConfig()
}

struct DefaultLectorEtiquetasFoodRiskScoringEngine: LectorEtiquetasFoodRiskScoring {
    private let config: LectorEtiquetasFoodRiskScoringConfig

    init(config: LectorEtiquetasFoodRiskScoringConfig = .default) {
        self.config = config
    }

    func score(input: LectorEtiquetasFoodRiskScoringInput) -> LectorEtiquetasFoodRiskScoreResult {
        let additiveFindings = input.hallazgos.filter { $0.categoria == .aditivoDeRiesgo }
        let exceedsSaturatedFatExcellentThreshold = hasSaturatedFatAboveFiveGramsPer100g(input: input)

        if let novaClassification = classificationFromNovaOverride(input: input, additiveFindings: additiveFindings) {
            let adjustedNovaClassification: LectorEtiquetasFoodRiskClassification
            if novaClassification == .excelente, exceedsSaturatedFatExcellentThreshold {
                adjustedNovaClassification = .bueno
            } else {
                adjustedNovaClassification = novaClassification
            }
            let score = adjustedNovaClassification == .excelente ? config.excelenteMinScore : config.buenoMinScore
            return LectorEtiquetasFoodRiskScoreResult(
                score: score,
                classification: adjustedNovaClassification,
                criteriosEvaluados: 2,
                criteriosSinDatos: 0
            )
        }

        if hasCriticalAdditivePattern(additiveFindings) {
            return LectorEtiquetasFoodRiskScoreResult(
                score: 0,
                classification: .malo,
                criteriosEvaluados: 1,
                criteriosSinDatos: 0
            )
        }

        if isInsufficientInformation(input: input) {
            return LectorEtiquetasFoodRiskScoreResult(
                score: config.insufficientInfoLowScore,
                classification: .informacionInsuficiente,
                criteriosEvaluados: 0,
                criteriosSinDatos: 3
            )
        }

        var score = 100.0
        var criteriosEvaluados = 0
        var criteriosSinDatos = 0
        if input.ingredientesDetectadosCount > 0 {
            criteriosEvaluados += 1
            if additiveFindings.isEmpty {
                score += config.noAdditivesBonus
            } else {
                score -= config.additivePresencePenalty
                score -= min(Double(additiveFindings.count) * config.additivePerItemPenalty, config.additivePerItemPenaltyCap)

                let additiveSeverityPenalty = additiveFindings
                    .map { severityPenaltyForAdditive(level: $0.nivel) }
                    .reduce(0, +)
                score -= min(additiveSeverityPenalty, config.additiveSeverityPenaltyCap)
            }
        } else {
            criteriosSinDatos += 1
        }

        if let esOrganico = input.perfilAlimentario.esOrganico {
            criteriosEvaluados += 1
            score += esOrganico ? config.organicTrueBonus : -config.organicFalsePenalty
        } else if !input.evaluacionEcologica.evidencias.isEmpty {
            criteriosEvaluados += 1
            switch input.evaluacionEcologica.estado {
            case .confirmado:
                score += config.ecologicalConfirmedBonus
            case .probable:
                score += config.ecologicalProbableBonus
            case .noConfirmado:
                score -= config.ecologicalUnconfirmedPenalty
            }
        } else {
            criteriosEvaluados += 1
            score -= config.organicUnknownPenalty
        }

        if let contieneGluten = input.perfilAlimentario.contieneGluten {
            criteriosEvaluados += 1
            score += contieneGluten ? -config.glutenPresentPenalty : config.glutenAbsentBonus
        } else if let glutenFinding = input.hallazgos
            .filter({ $0.categoria == .indicioGluten })
            .max(by: { $0.nivel.rawValue < $1.nivel.rawValue }) {
            criteriosEvaluados += 1
            score -= glutenPenaltyFromFinding(glutenFinding.nivel)
        } else if containsGlutenMarkers(in: input.alergenos) {
            criteriosEvaluados += 1
            score -= config.glutenPresentPenalty * 0.7
        } else {
            criteriosEvaluados += 1
            score -= config.glutenUnknownPenalty
        }

        let sugarEvaluation = evaluateNutrient(
            canonicalName: "azucar",
            aliases: ["sugars", "sugar"],
            nutrients: input.nutrientesDetectados,
            formattedNutrients: input.nutrimentsFormatted,
            fallbackFinding: input.hallazgos.first(where: { $0.categoria == .excesoAzucar }),
            levelFunction: riskLevelForSugar
        )
        applyNutrientScore(
            sugarEvaluation,
            criteriosEvaluados: &criteriosEvaluados,
            criteriosSinDatos: &criteriosSinDatos,
            score: &score,
            penaltiesByLevel: config.sugarPenaltyByLevel,
            lowRiskBonus: config.lowSugarBonus
        )

        let saltEvaluation = evaluateNutrient(
            canonicalName: "sal",
            aliases: ["salt"],
            nutrients: input.nutrientesDetectados,
            formattedNutrients: input.nutrimentsFormatted,
            fallbackFinding: input.hallazgos.first(where: { $0.categoria == .excesoSal || $0.categoria == .sodioElevado }),
            levelFunction: riskLevelForSalt
        )
        applyNutrientScore(
            saltEvaluation,
            criteriosEvaluados: &criteriosEvaluados,
            criteriosSinDatos: &criteriosSinDatos,
            score: &score,
            penaltiesByLevel: config.saltPenaltyByLevel,
            lowRiskBonus: config.lowSaltBonus
        )

        let saturatedFatEvaluation = evaluateNutrient(
            canonicalName: "grasa_saturada",
            aliases: ["saturatedfat"],
            nutrients: input.nutrientesDetectados,
            formattedNutrients: input.nutrimentsFormatted,
            fallbackFinding: input.hallazgos.first(where: { $0.categoria == .excesoGrasaSaturada }),
            levelFunction: riskLevelForSaturatedFat
        )
        applyNutrientScore(
            saturatedFatEvaluation,
            criteriosEvaluados: &criteriosEvaluados,
            criteriosSinDatos: &criteriosSinDatos,
            score: &score,
            penaltiesByLevel: config.saturatedFatPenaltyByLevel,
            lowRiskBonus: config.lowSaturatedFatBonus
        )

        let fiberMeasurement = bestMeasurement(
            canonicalName: "fibra",
            aliases: ["fiber", "fibre", "dietaryfiber"],
            nutrients: input.nutrientesDetectados,
            formattedNutrients: input.nutrimentsFormatted
        )

        if let fiberMeasurement {
            criteriosEvaluados += 1
            switch fiberLevel(for: fiberMeasurement) {
            case .baja:
                score -= config.lowFiberPenalty
            case .alta:
                score += config.highFiberBonus
            case .media:
                break
            }
        } else {
            criteriosSinDatos += 1
        }

        let missingPenalty = min(Double(criteriosSinDatos) * config.missingCriterionPenalty, config.maxMissingPenalty)
        score -= missingPenalty

        let boundedScore = Int(clamp(score, min: 0, max: 100).rounded())

        let classification: LectorEtiquetasFoodRiskClassification
        if boundedScore >= config.excelenteMinScore {
            classification = .excelente
        } else if boundedScore >= config.buenoMinScore {
            classification = .bueno
        } else {
            classification = .malo
        }
        let adjustedClassification: LectorEtiquetasFoodRiskClassification
        if classification == .excelente, exceedsSaturatedFatExcellentThreshold {
            adjustedClassification = .bueno
        } else {
            adjustedClassification = classification
        }

        return LectorEtiquetasFoodRiskScoreResult(
            score: boundedScore,
            classification: adjustedClassification,
            criteriosEvaluados: criteriosEvaluados,
            criteriosSinDatos: criteriosSinDatos
        )
    }

    private func severityPenaltyForAdditive(level: NivelRiesgoEtiqueta) -> Double {
        switch level {
        case .bajo: return 1
        case .medio: return 3
        case .alto: return 6
        case .critico: return 10
        }
    }

    private func hasCriticalAdditivePattern(_ findings: [HallazgoRiesgoEtiqueta]) -> Bool {
        let highOrCriticalCount = findings.filter { $0.nivel == .alto || $0.nivel == .critico }.count
        if highOrCriticalCount >= 1 {
            return true
        }

        let mediumCount = findings.filter { $0.nivel == .medio }.count
        return mediumCount >= 3
    }

    private func classificationFromNovaOverride(
        input: LectorEtiquetasFoodRiskScoringInput,
        additiveFindings: [HallazgoRiesgoEtiqueta]
    ) -> LectorEtiquetasFoodRiskClassification? {
        guard let nova = input.novaGroup, (1...2).contains(nova) else { return nil }
        guard !hasAdditiveRiskAtOrAboveMedium(additiveFindings) else { return nil }

        let containsGluten = inferredContainsGluten(input: input)
        let isOrganic = input.perfilAlimentario.esOrganico

        // Regla prioritaria NOVA 1/2:
        // - Excelente solo si gluten == false y orgánico == true.
        // - Bueno en cualquier otro caso (incluye valores faltantes).
        if containsGluten == false, isOrganic == true {
            return .excelente
        }

        return .bueno
    }

    private func hasAdditiveRiskAtOrAboveMedium(_ findings: [HallazgoRiesgoEtiqueta]) -> Bool {
        findings.contains { finding in
            finding.nivel == .medio || finding.nivel == .alto || finding.nivel == .critico
        }
    }

    private func inferredContainsGluten(input: LectorEtiquetasFoodRiskScoringInput) -> Bool? {
        if let containsGluten = input.perfilAlimentario.contieneGluten {
            return containsGluten
        }

        if input.hallazgos.contains(where: { $0.categoria == .indicioGluten }) {
            return true
        }

        if containsGlutenMarkers(in: input.alergenos) {
            return true
        }

        return nil
    }

    private func glutenPenaltyFromFinding(_ level: NivelRiesgoEtiqueta) -> Double {
        switch level {
        case .bajo: return 4
        case .medio: return 8
        case .alto: return 14
        case .critico: return 18
        }
    }

    private func containsGlutenMarkers(in allergens: [String]) -> Bool {
        let markers = ["gluten", "trigo", "wheat", "cebada", "barley", "centeno", "rye", "espelta", "spelt"]
        return allergens.contains { allergen in
            let normalized = normalize(allergen)
            return markers.contains(where: { normalized.contains($0) })
        }
    }

    private func evaluateNutrient(
        canonicalName: String,
        aliases: [String],
        nutrients: [NutrienteEtiqueta],
        formattedNutrients: [OpenFoodFactsNutrimentItem],
        fallbackFinding: HallazgoRiesgoEtiqueta?,
        levelFunction: (Double, BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta
    ) -> NutrientEvaluation {
        if let measurement = bestMeasurement(
            canonicalName: canonicalName,
            aliases: aliases,
            nutrients: nutrients,
            formattedNutrients: formattedNutrients
        ) {
            let level = levelFunction(measurement.grams, measurement.base)
            return .data(level)
        }

        if let fallbackFinding {
            return .data(fallbackFinding.nivel)
        }

        return .missing
    }

    private func applyNutrientScore(
        _ evaluation: NutrientEvaluation,
        criteriosEvaluados: inout Int,
        criteriosSinDatos: inout Int,
        score: inout Double,
        penaltiesByLevel: [NivelRiesgoEtiqueta: Double],
        lowRiskBonus: Double
    ) {
        switch evaluation {
        case .missing:
            criteriosSinDatos += 1
        case .data(let level):
            criteriosEvaluados += 1
            if level == .bajo {
                score += lowRiskBonus
            } else {
                score -= penaltiesByLevel[level] ?? 0
            }
        }
    }

    private func bestMeasurement(
        canonicalName: String,
        aliases: [String],
        nutrients: [NutrienteEtiqueta],
        formattedNutrients: [OpenFoodFactsNutrimentItem]
    ) -> NutrientMeasurement? {
        let directCandidates = nutrients
            .filter { $0.nombre == canonicalName }
            .map { NutrientMeasurement(grams: valueInGrams($0.valor, unit: $0.unidad), base: $0.base) }

        if let bestDirect = directCandidates.sorted(by: measurementPriority).first {
            return bestDirect
        }

        let aliasSet = Set((aliases + [canonicalName]).map(normalize))
        let parsedCandidates = formattedNutrients.compactMap { item -> NutrientMeasurement? in
            let normalizedKey = normalize(item.key)
            guard aliasSet.contains(where: { normalizedKey.hasPrefix($0) }) else { return nil }
            guard let number = firstNumber(in: item.valueText) else { return nil }

            let unit: UnidadNutrienteEtiqueta = normalize(item.valueText).contains("mg") ? .mg : .g
            let base: BaseMedicionEtiqueta
            if normalizedKey.contains("100g") || normalizedKey.contains("100ml") {
                base = .por100g
            } else if normalizedKey.contains("serving") || normalizedKey.contains("porcion") {
                base = .porPorcion
            } else {
                base = .desconocida
            }

            return NutrientMeasurement(grams: valueInGrams(number, unit: unit), base: base)
        }

        return parsedCandidates.sorted(by: measurementPriority).first
    }

    private func measurementPriority(_ lhs: NutrientMeasurement, _ rhs: NutrientMeasurement) -> Bool {
        baseRank(lhs.base) < baseRank(rhs.base)
    }

    private func baseRank(_ base: BaseMedicionEtiqueta) -> Int {
        switch base {
        case .por100g: return 0
        case .porPorcion: return 1
        case .desconocida: return 2
        }
    }

    private func valueInGrams(_ value: Double, unit: UnidadNutrienteEtiqueta) -> Double {
        switch unit {
        case .g: return value
        case .mg: return value / 1_000
        }
    }

    private func firstNumber(in text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "−", with: "-")

        let pattern = #"[-+]?[0-9]*\.?[0-9]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(location: 0, length: normalized.utf16.count)
        guard let match = regex.firstMatch(in: normalized, range: range),
              let swiftRange = Range(match.range, in: normalized) else {
            return nil
        }

        return Double(String(normalized[swiftRange]))
    }

    private func riskLevelForSugar(grams: Double, base: BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta {
        switch base {
        case .por100g:
            if grams >= 35 { return .critico }
            if grams >= 22.5 { return .alto }
            if grams >= 5 { return .medio }
            return .bajo
        case .porPorcion:
            if grams >= 25 { return .critico }
            if grams >= 15 { return .alto }
            if grams >= 8 { return .medio }
            return .bajo
        case .desconocida:
            if grams >= 22.5 { return .alto }
            if grams >= 10 { return .medio }
            return .bajo
        }
    }

    private func riskLevelForSalt(grams: Double, base: BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta {
        switch base {
        case .por100g:
            if grams >= 2.5 { return .critico }
            if grams >= 1.5 { return .alto }
            if grams >= 0.3 { return .medio }
            return .bajo
        case .porPorcion:
            if grams >= 1.5 { return .critico }
            if grams >= 1.2 { return .alto }
            if grams >= 0.3 { return .medio }
            return .bajo
        case .desconocida:
            if grams >= 1.5 { return .alto }
            if grams >= 0.3 { return .medio }
            return .bajo
        }
    }

    private func riskLevelForSaturatedFat(grams: Double, base: BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta {
        switch base {
        case .por100g:
            if grams >= 8 { return .critico }
            if grams > 5 { return .alto }
            if grams >= 1.5 { return .medio }
            return .bajo
        case .porPorcion:
            if grams >= 8 { return .critico }
            if grams >= 5 { return .alto }
            if grams >= 2 { return .medio }
            return .bajo
        case .desconocida:
            if grams >= 5 { return .alto }
            if grams >= 1.5 { return .medio }
            return .bajo
        }
    }

    private func hasSaturatedFatAboveFiveGramsPer100g(input: LectorEtiquetasFoodRiskScoringInput) -> Bool {
        guard let measurement = bestMeasurement(
            canonicalName: "grasa_saturada",
            aliases: ["saturatedfat"],
            nutrients: input.nutrientesDetectados,
            formattedNutrients: input.nutrimentsFormatted
        ) else {
            return false
        }

        guard measurement.base == .por100g else { return false }
        return measurement.grams > 5
    }

    private func fiberLevel(for measurement: NutrientMeasurement) -> FiberLevel {
        switch measurement.base {
        case .por100g:
            if measurement.grams >= 6 { return .alta }
            if measurement.grams < 3 { return .baja }
            return .media
        case .porPorcion:
            if measurement.grams >= 3 { return .alta }
            if measurement.grams < 1.5 { return .baja }
            return .media
        case .desconocida:
            if measurement.grams >= 3 { return .alta }
            if measurement.grams < 1.5 { return .baja }
            return .media
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    private func isInsufficientInformation(input: LectorEtiquetasFoodRiskScoringInput) -> Bool {
        let missingNutritionalComposition = !hasNutritionalCompositionData(input: input)
        return missingNutritionalComposition
    }

    private func hasNutritionalCompositionData(input: LectorEtiquetasFoodRiskScoringInput) -> Bool {
        if !input.nutrientesDetectados.isEmpty || !input.nutrimentsFormatted.isEmpty {
            return true
        }

        return input.hallazgos.contains { hallazgo in
            hallazgo.categoria == .excesoAzucar ||
            hallazgo.categoria == .excesoSal ||
            hallazgo.categoria == .sodioElevado ||
            hallazgo.categoria == .excesoGrasaSaturada
        }
    }
}

private struct NutrientMeasurement {
    let grams: Double
    let base: BaseMedicionEtiqueta
}

private enum NutrientEvaluation {
    case data(NivelRiesgoEtiqueta)
    case missing
}

private enum FiberLevel {
    case baja
    case media
    case alta
}
