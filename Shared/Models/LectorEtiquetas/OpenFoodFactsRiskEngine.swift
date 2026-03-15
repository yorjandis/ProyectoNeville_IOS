//
//  OpenFoodFactsRiskEngine.swift
//  Neville_iOS
//
//  Created by Codex on 13/03/26.
//

import Foundation

struct OpenFoodFactsRiskEngine {
    private let additiveCatalog: [AdditiveCatalogItem]

    private let glutenMarkers: [String] = [
        "gluten", "trigo", "wheat", "cebada", "barley", "centeno", "rye", "espelta", "spelt", "kamut", "triticale", "malta", "semola", "semolina", "harina de trigo", "proteina de trigo"
    ]

    private let glutenExclusions: [String] = ["maltodextrina", "maltodextrin"]

    init(additiveCatalog: [AdditiveCatalogItem] = AdditivesCatalogLoader.loadFromBundle()) {
        self.additiveCatalog = additiveCatalog
    }

    func analyze(product: OpenFoodFactsProduct) -> ResultadoAnalisisEtiqueta {
        let ingredientes = splitIngredients(product.ingredientsText)
        let nutrientes = mapNutrients(product.nutriments)

        var hallazgos: [HallazgoRiesgoEtiqueta] = []
        hallazgos.append(contentsOf: detectAditivos(product: product, ingredientes: ingredientes))
        hallazgos.append(contentsOf: detectGluten(product: product, ingredientes: ingredientes))
        hallazgos.append(contentsOf: detectNutritionRisks(nutrientes: nutrientes))

        if ingredientes.count >= 18 {
            hallazgos.append(
                HallazgoRiesgoEtiqueta(
                    categoria: .ultraprocesado,
                    nivel: .medio,
                    titulo: "Lista extensa de ingredientes",
                    detalle: "Se detectaron \(ingredientes.count) ingredientes, posible perfil ultraprocesado.",
                    textoDetectado: "\(ingredientes.count) ingredientes",
                    recomendacion: "Compara con opciones de lista corta de ingredientes y menor procesamiento."
                )
            )
        }

        let uniqueFindings = deduplicateFindings(hallazgos)
        let nivelGeneral = uniqueFindings.map(\.nivel).max() ?? .bajo

        return ResultadoAnalisisEtiqueta(
            textoDetectado: buildReadableSource(product: product),
            ingredientesDetectados: ingredientes,
            nutrientesDetectados: nutrientes,
            hallazgos: uniqueFindings,
            nivelGeneral: nivelGeneral,
            metadata: nil
        )
    }

    private func detectAditivos(product: OpenFoodFactsProduct, ingredientes: [String]) -> [HallazgoRiesgoEtiqueta] {
        guard !additiveCatalog.isEmpty else { return [] }

        let corpus = buildCorpus(product: product, ingredientes: ingredientes)
        let normalizedCorpus = corpus.map { (original: $0, normalized: normalize($0)) }
        var findings: [HallazgoRiesgoEtiqueta] = []

        for additive in additiveCatalog {
            let aliases = additive.allSearchAliases.filter { shouldUseAlias($0) }
            let evidencias = detectEvidence(for: additive, aliases: aliases, in: normalizedCorpus)
            guard !evidencias.isEmpty else { continue }

            findings.append(
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

        return findings
    }

    private func detectEvidence(
        for additive: AdditiveCatalogItem,
        aliases: [String],
        in normalizedCorpus: [(original: String, normalized: String)]
    ) -> [String] {
        var evidencias: [String] = []

        for line in normalizedCorpus {
            if containsECode(additive.normalizedECode, in: line.normalized) {
                evidencias.append(line.original)
                continue
            }

            if aliases.contains(where: { containsAliasMatch($0, in: line.normalized) }) {
                evidencias.append(line.original)
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
        var searchRange: Range<String.Index>? = normalizedText.startIndex..<normalizedText.endIndex

        while let range = normalizedText.range(of: alias, options: [], range: searchRange) {
            let hasValidStartBoundary: Bool = {
                guard range.lowerBound > normalizedText.startIndex else { return true }
                let before = normalizedText[normalizedText.index(before: range.lowerBound)]
                return !before.isLetter && !before.isNumber
            }()

            let hasValidEndBoundary: Bool = {
                guard range.upperBound < normalizedText.endIndex else { return true }
                let after = normalizedText[range.upperBound]
                return !after.isLetter && !after.isNumber
            }()

            if hasValidStartBoundary && hasValidEndBoundary {
                return true
            }

            searchRange = range.upperBound..<normalizedText.endIndex
        }

        return false
    }

    private func containsECode(_ normalizedCode: String, in normalizedText: String) -> Bool {
        guard normalizedCode.first == "e", normalizedCode.count > 1 else {
            return containsAliasMatch(normalizedCode, in: normalizedText)
        }

        let codeBody = String(normalizedCode.dropFirst())
        var index = normalizedText.startIndex

        while index < normalizedText.endIndex {
            guard normalizedText[index] == "e" else {
                index = normalizedText.index(after: index)
                continue
            }

            let hasValidStartBoundary: Bool = {
                guard index > normalizedText.startIndex else { return true }
                let before = normalizedText[normalizedText.index(before: index)]
                return !before.isLetter && !before.isNumber
            }()

            guard hasValidStartBoundary else {
                index = normalizedText.index(after: index)
                continue
            }

            var probe = normalizedText.index(after: index)
            while probe < normalizedText.endIndex,
                  normalizedText[probe] == " " || normalizedText[probe] == "-" {
                probe = normalizedText.index(after: probe)
            }

            guard normalizedText[probe...].hasPrefix(codeBody) else {
                index = normalizedText.index(after: index)
                continue
            }

            let end = normalizedText.index(probe, offsetBy: codeBody.count)
            let hasValidEndBoundary: Bool = {
                guard end < normalizedText.endIndex else { return true }
                let after = normalizedText[end]
                return !after.isLetter && !after.isNumber
            }()

            if hasValidEndBoundary {
                return true
            }

            index = normalizedText.index(after: index)
        }

        return false
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

    private func detectGluten(product: OpenFoodFactsProduct, ingredientes: [String]) -> [HallazgoRiesgoEtiqueta] {
        let corpus = buildCorpus(product: product, ingredientes: ingredientes)
        let evidencias = corpus.filter { line in
            let normalized = normalize(line)
            let hasExclusion = glutenExclusions.contains(where: { normalized.contains($0) })
            let explicitGluten = normalized.contains("gluten")
            if hasExclusion && !explicitGluten { return false }
            return glutenMarkers.contains(where: { normalized.contains($0) })
        }

        let uniques = evidencias.orderedUnique().sorted()
        guard !uniques.isEmpty else { return [] }

        let nivel: NivelRiesgoEtiqueta = uniques.contains(where: { normalize($0).contains("gluten") }) ? .alto : .medio

        return [
            HallazgoRiesgoEtiqueta(
                categoria: .indicioGluten,
                nivel: nivel,
                titulo: "Posibles indicios de gluten",
                detalle: "Se detectaron referencias a posible presencia de gluten.",
                textoDetectado: uniques.joined(separator: ", "),
                recomendacion: "Si necesitas evitar gluten, confirma alérgenos y certificación sin gluten."
            )
        ]
    }

    private func detectNutritionRisks(nutrientes: [NutrienteEtiqueta]) -> [HallazgoRiesgoEtiqueta] {
        var findings: [HallazgoRiesgoEtiqueta] = []

        if let sugar = bestNutrient(named: "azucar", nutrients: nutrientes) {
            let nivel = riskSugar(grams: grams(sugar), base: sugar.base)
            if nivel > .bajo {
                findings.append(HallazgoRiesgoEtiqueta(categoria: .excesoAzucar, nivel: nivel, titulo: "Azúcar elevada", detalle: "Concentración alta de azúcar para \(sugar.base.rawValue).", textoDetectado: describe(sugar), recomendacion: "Prioriza opciones con menor azúcar total."))
            }
        }

        if let salt = bestNutrient(named: "sal", nutrients: nutrientes) {
            let nivel = riskSalt(grams: grams(salt), base: salt.base)
            if nivel > .bajo {
                findings.append(HallazgoRiesgoEtiqueta(categoria: .excesoSal, nivel: nivel, titulo: "Sal elevada", detalle: "Concentración alta de sal para \(salt.base.rawValue).", textoDetectado: describe(salt), recomendacion: "Reduce frecuencia y combina con alimentos bajos en sal."))
            }
        }

        if let satFat = bestNutrient(named: "grasa_saturada", nutrients: nutrientes) {
            let nivel = riskSaturatedFat(grams: grams(satFat), base: satFat.base)
            if nivel > .bajo {
                findings.append(HallazgoRiesgoEtiqueta(categoria: .excesoGrasaSaturada, nivel: nivel, titulo: "Grasa saturada elevada", detalle: "Concentración alta de grasa saturada para \(satFat.base.rawValue).", textoDetectado: describe(satFat), recomendacion: "Prioriza grasas no saturadas y menor ultraprocesado."))
            }
        }

        if let sodium = bestNutrient(named: "sodio", nutrients: nutrientes) {
            let salEquivalente = grams(sodium) * 2.5
            let nivel = riskSalt(grams: salEquivalente, base: sodium.base)
            if nivel > .bajo {
                findings.append(HallazgoRiesgoEtiqueta(categoria: .sodioElevado, nivel: nivel, titulo: "Sodio elevado", detalle: "Equivale a \(String(format: "%.2f", salEquivalente)) g de sal para \(sodium.base.rawValue).", textoDetectado: describe(sodium), recomendacion: "Busca versiones con menor sodio."))
            }
        }

        return findings
    }

    private func mapNutrients(_ n: OpenFoodFactsNutriments?) -> [NutrienteEtiqueta] {
        guard let n else { return [] }
        var out: [NutrienteEtiqueta] = []

        addNutrient(name: "azucar", value: n.sugars100g, unit: n.sugarsUnit, base: .por100g, into: &out)
        addNutrient(name: "azucar", value: n.sugarsServing, unit: n.sugarsUnit, base: .porPorcion, into: &out)

        addNutrient(name: "sal", value: n.salt100g, unit: n.saltUnit, base: .por100g, into: &out)
        addNutrient(name: "sal", value: n.saltServing, unit: n.saltUnit, base: .porPorcion, into: &out)

        addNutrient(name: "grasa_saturada", value: n.saturatedFat100g, unit: n.saturatedFatUnit, base: .por100g, into: &out)
        addNutrient(name: "grasa_saturada", value: n.saturatedFatServing, unit: n.saturatedFatUnit, base: .porPorcion, into: &out)

        addNutrient(name: "sodio", value: n.sodium100g, unit: n.sodiumUnit, base: .por100g, into: &out)
        addNutrient(name: "sodio", value: n.sodiumServing, unit: n.sodiumUnit, base: .porPorcion, into: &out)

        return deduplicateNutrients(out)
    }

    private func addNutrient(name: String, value: Double?, unit: String?, base: BaseMedicionEtiqueta, into out: inout [NutrienteEtiqueta]) {
        guard let value, value >= 0 else { return }
        let normalized = normalizeUnit(unit)
        out.append(NutrienteEtiqueta(nombre: name, valor: value, unidad: normalized, base: base))
    }

    private func normalizeUnit(_ unit: String?) -> UnidadNutrienteEtiqueta {
        let u = (unit ?? "g").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return u == "mg" ? .mg : .g
    }

    private func splitIngredients(_ text: String?) -> [String] {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return text
            .components(separatedBy: CharacterSet(charactersIn: ",;."))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func buildCorpus(product: OpenFoodFactsProduct, ingredientes: [String]) -> [String] {
        var corpus: [String] = ingredientes
        if let allergens = product.allergens, !allergens.isEmpty { corpus.append(allergens) }
        if let ingredientsText = product.ingredientsText, !ingredientsText.isEmpty { corpus.append(ingredientsText) }
        return corpus.orderedUnique()
    }

    private func buildReadableSource(product: OpenFoodFactsProduct) -> String {
        var lines: [String] = []
        if let code = product.code { lines.append("Codigo: \(code)") }
        if let name = product.productName { lines.append("Producto: \(name)") }
        if let ingredients = product.ingredientsText { lines.append("Ingredientes: \(ingredients)") }
        if let allergens = product.allergens, !allergens.isEmpty { lines.append("Alergenos: \(allergens)") }
        return lines.joined(separator: "\n")
    }

    private func bestNutrient(named name: String, nutrients: [NutrienteEtiqueta]) -> NutrienteEtiqueta? {
        let candidates = nutrients.filter { $0.nombre == name }
        guard !candidates.isEmpty else { return nil }
        return candidates.sorted { lhs, rhs in
            if lhs.base == rhs.base { return grams(lhs) > grams(rhs) }
            return basePriority(lhs.base) < basePriority(rhs.base)
        }.first
    }

    private func basePriority(_ base: BaseMedicionEtiqueta) -> Int {
        switch base {
        case .por100g: return 0
        case .porPorcion: return 1
        case .desconocida: return 2
        }
    }

    private func riskSugar(grams: Double, base: BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta {
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

    private func riskSalt(grams: Double, base: BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta {
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

    private func riskSaturatedFat(grams: Double, base: BaseMedicionEtiqueta) -> NivelRiesgoEtiqueta {
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

    private func grams(_ nutrient: NutrienteEtiqueta) -> Double {
        switch nutrient.unidad {
        case .g: return nutrient.valor
        case .mg: return nutrient.valor / 1000
        }
    }

    private func describe(_ nutrient: NutrienteEtiqueta) -> String {
        "\(nutrient.valor) \(nutrient.unidad.rawValue) (\(nutrient.base.rawValue))"
    }

    private func deduplicateNutrients(_ nutrients: [NutrienteEtiqueta]) -> [NutrienteEtiqueta] {
        var map: [String: NutrienteEtiqueta] = [:]
        for nutrient in nutrients {
            let key = "\(nutrient.nombre)-\(nutrient.base.rawValue)"
            if let current = map[key] {
                if grams(nutrient) > grams(current) {
                    map[key] = nutrient
                }
            } else {
                map[key] = nutrient
            }
        }
        return Array(map.values)
    }

    private func deduplicateFindings(_ findings: [HallazgoRiesgoEtiqueta]) -> [HallazgoRiesgoEtiqueta] {
        var map: [String: HallazgoRiesgoEtiqueta] = [:]
        for finding in findings {
            let key = "\(finding.categoria.rawValue)|\(normalize(finding.titulo))"
            if let current = map[key] {
                if finding.nivel > current.nivel {
                    map[key] = finding
                }
            } else {
                map[key] = finding
            }
        }
        return Array(map.values).sorted { $0.nivel.rawValue > $1.nivel.rawValue }
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
