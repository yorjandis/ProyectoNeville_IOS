//
//  LectorEtiquetasRiskEvaluator.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

struct DefaultEtiquetaRiskEvaluator: EtiquetaRiskEvaluating {
    private let additives: [AdditiveCatalogItem]

    private let marcadoresGluten: [String] = [
        "gluten", "trigo", "wheat", "cebada", "barley", "centeno", "rye", "espelta", "spelt", "kamut", "triticale", "malta", "semola", "semolina", "harina de trigo", "proteina de trigo"
    ]

    private let exclusionesGluten: [String] = [
        "maltodextrina",
        "maltodextrin"
    ]

    init(additives: [AdditiveCatalogItem] = AdditivesCatalogLoader.loadFromBundle()) {
        self.additives = additives
    }

    func evaluate(parseResult: EtiquetaParseResult) -> [HallazgoRiesgoEtiqueta] {
        var hallazgos: [HallazgoRiesgoEtiqueta] = []

        hallazgos.append(contentsOf: evaluateAdditives(ingredientes: parseResult.ingredientes, fullText: parseResult.originalText))
        hallazgos.append(contentsOf: evaluateGlutenIndicators(ingredientes: parseResult.ingredientes, fullText: parseResult.originalText))
        hallazgos.append(contentsOf: evaluateNutrientes(parseResult.nutrientes, fallbackBase: parseResult.baseDetectada))

        if parseResult.ingredientes.count >= 18 {
            hallazgos.append(
                HallazgoRiesgoEtiqueta(
                    categoria: .ultraprocesado,
                    nivel: .medio,
                    titulo: "Lista extensa de ingredientes",
                    detalle: "Se detectaron \(parseResult.ingredientes.count) ingredientes, posible perfil ultraprocesado.",
                    textoDetectado: "\(parseResult.ingredientes.count) ingredientes",
                    recomendacion: "Compara con opciones de lista corta de ingredientes y menor procesamiento."
                )
            )
        }

        return deduplicateFindings(hallazgos)
    }

    private func evaluateAdditives(ingredientes: [String], fullText: String) -> [HallazgoRiesgoEtiqueta] {
        guard !additives.isEmpty else { return [] }

        let corpus = buildSearchCorpus(ingredientes: ingredientes, fullText: fullText)
        var hallazgos: [HallazgoRiesgoEtiqueta] = []

        for additive in additives {
            let evidencias = detectEvidence(for: additive, in: corpus)
            guard !evidencias.isEmpty else { continue }

            hallazgos.append(
                HallazgoRiesgoEtiqueta(
                    categoria: .aditivoDeRiesgo,
                    nivel: riskLevel(for: additive),
                    titulo: "Aditivo detectado: \(additive.eCode.uppercased()) - \(additive.title)",
                    detalle: additive.cleanedInfo,
                    textoDetectado: evidencias.joined(separator: ", "),
                    recomendacion: "Tipo: \(additive.eType). Estado halal: \(additive.halalStatus). Toxicidad: \(additive.toxicidad)."
                )
            )
        }

        return hallazgos
    }

    private func detectEvidence(for additive: AdditiveCatalogItem, in corpus: [String]) -> [String] {
        var evidencias: [String] = []

        for line in corpus {
            let normalizedLine = normalize(line)

            if containsECode(additive.normalizedECode, in: normalizedLine) {
                evidencias.append(line)
                continue
            }

            let aliases = additive.allSearchAliases.filter { shouldUseAlias($0) }
            if aliases.contains(where: { containsAliasMatch($0, in: normalizedLine) }) {
                evidencias.append(line)
            }
        }

        return evidencias.orderedUnique().sorted()
    }

    private func shouldUseAlias(_ alias: String) -> Bool {
        if alias.count < 6 && !alias.contains(" ") { return false }
        if alias.split(separator: " ").count == 1 && genericSingleTokenAliases.contains(alias) { return false }
        return !genericAliasStopwords.contains(alias)
    }

    private var genericAliasStopwords: Set<String> {
        ["yellow", "orange", "brown", "green", "red", "unknown", "color", "colour", "colours", "salt", "salts", "acids"]
    }

    private var genericSingleTokenAliases: Set<String> {
        ["calcium", "potassium", "sodium", "magnesium", "ammonium", "ammonia", "fosfato", "phosphate"]
    }

    private func containsAliasMatch(_ alias: String, in normalizedText: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: alias)
        let pattern = "(^|[^\\p{L}\\p{N}])\(escaped)(?=$|[^\\p{L}\\p{N}])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return normalizedText.contains(alias)
        }

        let range = NSRange(location: 0, length: normalizedText.utf16.count)
        return regex.firstMatch(in: normalizedText, range: range) != nil
    }

    private func containsECode(_ normalizedCode: String, in normalizedText: String) -> Bool {
        guard normalizedCode.first == "e", normalizedCode.count > 1 else {
            return normalizedText.contains(normalizedCode)
        }

        let codeBody = String(normalizedCode.dropFirst())
        let escaped = NSRegularExpression.escapedPattern(for: codeBody)
        let pattern = "\\be[\\s\\-]*\(escaped)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return normalizedText.contains(normalizedCode)
        }

        let range = NSRange(location: 0, length: normalizedText.utf16.count)
        return regex.firstMatch(in: normalizedText, range: range) != nil
    }

    private func riskLevel(for additive: AdditiveCatalogItem) -> NivelRiesgoEtiqueta {
        switch normalize(additive.toxicidad) {
        case "alto":
            return .alto
        case "medio":
            return .medio
        default:
            return .bajo
        }
    }

    private func evaluateGlutenIndicators(ingredientes: [String], fullText: String) -> [HallazgoRiesgoEtiqueta] {
        var evidencias: [String] = []

        let coincidenciasIngredientes = ingredientes.filter { ingrediente in
            let normalized = normalize(ingrediente)
            let contieneExclusion = exclusionesGluten.contains(where: { normalized.contains($0) })
            let contieneGlutenExplicito = normalized.contains("gluten")
            if contieneExclusion && !contieneGlutenExplicito {
                return false
            }
            return marcadoresGluten.contains(where: { normalized.contains($0) })
        }
        evidencias.append(contentsOf: coincidenciasIngredientes)

        let lines = fullText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let coincidenciasTexto = lines.filter { line in
            let normalized = normalize(line)
            let contieneExclusion = exclusionesGluten.contains(where: { normalized.contains($0) })
            let contieneGlutenExplicito = normalized.contains("gluten")
            if contieneExclusion && !contieneGlutenExplicito {
                return false
            }

            let contieneMarcador = marcadoresGluten.contains(where: { normalized.contains($0) })
            let contieneAvisoAlergeno = normalized.contains("puede contener") || normalized.contains("trazas") || normalized.contains("contiene") || normalized.contains("alergen")
            return contieneMarcador && contieneAvisoAlergeno
        }
        evidencias.append(contentsOf: coincidenciasTexto)

        let evidenciasUnicas = evidencias.orderedUnique().sorted()

        guard !evidenciasUnicas.isEmpty else {
            return []
        }

        let detectaGlutenExplicito = evidenciasUnicas.contains {
            normalize($0).contains("gluten")
        }

        let nivel: NivelRiesgoEtiqueta = detectaGlutenExplicito ? .alto : .medio

        return [
            HallazgoRiesgoEtiqueta(
                categoria: .indicioGluten,
                nivel: nivel,
                titulo: "Posibles indicios de gluten",
                detalle: "Se detectaron referencias a posible presencia de gluten en la etiqueta.",
                textoDetectado: evidenciasUnicas.joined(separator: ", "),
                recomendacion: "Si necesitas evitar gluten, verifica certificación \"sin gluten\" y la sección de alérgenos."
            )
        ]
    }

    private func evaluateNutrientes(_ nutrientes: [NutrienteEtiqueta], fallbackBase: BaseMedicionEtiqueta) -> [HallazgoRiesgoEtiqueta] {
        var hallazgos: [HallazgoRiesgoEtiqueta] = []

        guard !nutrientes.isEmpty else { return hallazgos }

        if let azucar = selectBestNutrient(named: "azucar", in: nutrientes, fallbackBase: fallbackBase) {
            let nivel = riskLevelForSugar(grams: nutrientInGrams(azucar), base: azucar.base)
            if nivel > .bajo {
                hallazgos.append(buildHighSugarFinding(azucar, nivel: nivel))
            }
        }

        if let sal = selectBestNutrient(named: "sal", in: nutrientes, fallbackBase: fallbackBase) {
            let nivel = riskLevelForSalt(grams: nutrientInGrams(sal), base: sal.base)
            if nivel > .bajo {
                hallazgos.append(buildHighSaltFinding(sal, nivel: nivel))
            }
        }

        if let sodio = selectBestNutrient(named: "sodio", in: nutrientes, fallbackBase: fallbackBase) {
            let sodioEnSal = nutrientInGrams(sodio) * 2.5
            let nivel = riskLevelForSalt(grams: sodioEnSal, base: sodio.base)
            if nivel > .bajo {
                hallazgos.append(
                    HallazgoRiesgoEtiqueta(
                        categoria: .sodioElevado,
                        nivel: nivel,
                        titulo: "Sodio elevado",
                        detalle: "El sodio equivale aproximadamente a \(String(format: "%.2f", sodioEnSal)) g de sal (\(sodio.base.rawValue)).",
                        textoDetectado: "\(sodio.valor) \(sodio.unidad.rawValue) (\(sodio.base.rawValue))",
                        recomendacion: "Busca opciones con menor sodio para reducir el riesgo cardiovascular."
                    )
                )
            }
        }

        if let grasa = selectBestNutrient(named: "grasa_saturada", in: nutrientes, fallbackBase: fallbackBase) {
            let nivel = riskLevelForSaturatedFat(grams: nutrientInGrams(grasa), base: grasa.base)
            if nivel > .bajo {
                hallazgos.append(buildSaturatedFatFinding(grasa, nivel: nivel))
            }
        }

        return hallazgos
    }

    private func selectBestNutrient(named name: String, in nutrients: [NutrienteEtiqueta], fallbackBase: BaseMedicionEtiqueta) -> NutrienteEtiqueta? {
        let candidates = nutrients.filter { $0.nombre == name }
        guard !candidates.isEmpty else { return nil }

        let sorted = candidates.sorted { lhs, rhs in
            let lRank = basePriority(lhs.base, fallbackBase: fallbackBase)
            let rRank = basePriority(rhs.base, fallbackBase: fallbackBase)
            if lRank == rRank {
                return nutrientInGrams(lhs) > nutrientInGrams(rhs)
            }
            return lRank < rRank
        }

        return sorted.first
    }

    private func basePriority(_ base: BaseMedicionEtiqueta, fallbackBase: BaseMedicionEtiqueta) -> Int {
        let resolved = base == .desconocida ? fallbackBase : base
        switch resolved {
        case .por100g:
            return 0
        case .porPorcion:
            return 1
        case .desconocida:
            return 2
        }
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
            if grams >= 5 { return .alto }
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

    private func buildHighSugarFinding(_ nutrient: NutrienteEtiqueta, nivel: NivelRiesgoEtiqueta) -> HallazgoRiesgoEtiqueta {
        HallazgoRiesgoEtiqueta(
            categoria: .excesoAzucar,
            nivel: nivel,
            titulo: "Azúcar elevada",
            detalle: "La concentración de azúcar detectada es alta para \(nutrient.base.rawValue).",
            textoDetectado: "\(nutrient.valor) \(nutrient.unidad.rawValue) (\(nutrient.base.rawValue))",
            recomendacion: "Prioriza opciones con menor azúcar, especialmente para consumo frecuente."
        )
    }

    private func buildHighSaltFinding(_ nutrient: NutrienteEtiqueta, nivel: NivelRiesgoEtiqueta) -> HallazgoRiesgoEtiqueta {
        HallazgoRiesgoEtiqueta(
            categoria: .excesoSal,
            nivel: nivel,
            titulo: "Sal elevada",
            detalle: "La concentración de sal supera niveles recomendados para \(nutrient.base.rawValue).",
            textoDetectado: "\(nutrient.valor) \(nutrient.unidad.rawValue) (\(nutrient.base.rawValue))",
            recomendacion: "Alterna con productos de menor sal y controla la ingesta total diaria."
        )
    }

    private func buildSaturatedFatFinding(_ nutrient: NutrienteEtiqueta, nivel: NivelRiesgoEtiqueta) -> HallazgoRiesgoEtiqueta {
        HallazgoRiesgoEtiqueta(
            categoria: .excesoGrasaSaturada,
            nivel: nivel,
            titulo: "Grasa saturada elevada",
            detalle: "La concentración de grasa saturada es alta para \(nutrient.base.rawValue).",
            textoDetectado: "\(nutrient.valor) \(nutrient.unidad.rawValue) (\(nutrient.base.rawValue))",
            recomendacion: "Reduce frecuencia de consumo y compensa con grasas no saturadas."
        )
    }

    private func buildSearchCorpus(ingredientes: [String], fullText: String) -> [String] {
        var corpus = ingredientes

        let lines = fullText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        corpus.append(contentsOf: lines)
        return corpus.orderedUnique()
    }

    private func deduplicateFindings(_ findings: [HallazgoRiesgoEtiqueta]) -> [HallazgoRiesgoEtiqueta] {
        var map: [String: HallazgoRiesgoEtiqueta] = [:]

        for finding in findings {
            let key = "\(finding.categoria.rawValue)|\(normalize(finding.titulo))"
            if let existing = map[key] {
                if finding.nivel > existing.nivel {
                    map[key] = finding
                }
            } else {
                map[key] = finding
            }
        }

        return Array(map.values).sorted { $0.nivel.rawValue > $1.nivel.rawValue }
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
private extension Array where Element: Hashable {
    func orderedUnique() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

