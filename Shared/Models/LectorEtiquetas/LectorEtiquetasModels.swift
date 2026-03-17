//
//  LectorEtiquetasModels.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

enum LectorEtiquetasDataSource: String, Codable, CaseIterable, Identifiable {
    case openFoodFacts
    case offlineSQLite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openFoodFacts:
            return "API OpenFoodFacts"
        case .offlineSQLite:
            return "BD Offline"
        }
    }
}

enum NivelRiesgoEtiqueta: Int, Codable, Comparable {
    case bajo = 0
    case medio = 1
    case alto = 2
    case critico = 3

    static func < (lhs: NivelRiesgoEtiqueta, rhs: NivelRiesgoEtiqueta) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum CategoriaRiesgoEtiqueta: String, Codable {
    case aditivoDeRiesgo
    case excesoAzucar
    case excesoSal
    case excesoGrasaSaturada
    case sodioElevado
    case ultraprocesado
    case indicioGluten
}

enum UnidadNutrienteEtiqueta: String, Codable {
    case g
    case mg
}

enum BaseMedicionEtiqueta: String, Codable {
    case por100g
    case porPorcion
    case desconocida
}

struct NutrienteEtiqueta: Codable, Hashable {
    let nombre: String
    let valor: Double
    let unidad: UnidadNutrienteEtiqueta
    let base: BaseMedicionEtiqueta
}

struct HallazgoRiesgoEtiqueta: Codable, Hashable {
    let categoria: CategoriaRiesgoEtiqueta
    let nivel: NivelRiesgoEtiqueta
    let titulo: String
    let detalle: String
    let textoDetectado: String
    let recomendacion: String
}

struct OpenFoodFactsFieldItem: Codable, Hashable {
    let key: String
    let value: String
}

struct OpenFoodFactsNutrimentItem: Codable, Hashable {
    let key: String
    let displayName: String
    let valueText: String
}

struct AdditiveCatalogItem: Codable, Hashable {
    let id: Int
    let eCode: String
    let eType: String
    let halalStatus: String
    let info: String
    let title: String
    let aliases: [String]
    let toxicidad: String

    enum CodingKeys: String, CodingKey {
        case id
        case eCode = "e_code"
        case eType = "e_type"
        case halalStatus = "halal_status"
        case info
        case title
        case aliases
        case toxicidad
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        eCode = try container.decode(String.self, forKey: .eCode)
        eType = try container.decode(String.self, forKey: .eType)
        halalStatus = try container.decode(String.self, forKey: .halalStatus)
        info = try container.decode(String.self, forKey: .info)
        title = try container.decode(String.self, forKey: .title)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        toxicidad = try container.decodeIfPresent(String.self, forKey: .toxicidad)?.lowercased() ?? "medio"
    }

    var normalizedECode: String {
        eCode
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }

    var titleAliases: [String] {
        let normalizedTitle = title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let separators = CharacterSet(charactersIn: "/,;()")
        let parts = normalizedTitle
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 4 }

        return ([normalizedTitle] + parts).orderedUnique()
    }

    var allSearchAliases: [String] {
        let normalizedAliases = aliases
            .map {
                $0
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty }

        return (titleAliases + normalizedAliases).orderedUnique()
    }

    var cleanedInfo: String {
        info
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AdditivesCatalogLoader {
    static func loadFromBundle() -> [AdditiveCatalogItem] {
        guard let url = findCatalogURL() else { return [] }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([AdditiveCatalogItem].self, from: data)
            return decoded
        } catch {
            #if DEBUG
            print("[LectorEtiquetas] No se pudo cargar additives.json: \(error)")
            #endif
            return []
        }
    }

    private static func findCatalogURL() -> URL? {
        var bundles: [Bundle] = [Bundle.main]
        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)

        for bundle in bundles {
            if let url = bundle.url(forResource: "additives", withExtension: "json") {
                return url
            }
        }

        return nil
    }
}

struct OpenFoodFactsEcologicalData: Codable, Hashable {
    let labels: String
    let labelsTags: [String]
    let countries: String
    let countriesTags: [String]
    let origins: String
    let originsTags: [String]
    let certifications: String
    let certificationsTags: [String]
    let ecoscoreGrade: String
}

struct EtiquetaPerfilAlimentario: Codable, Hashable {
    let esVegano: Bool?
    let esVegetariano: Bool?
    let esOrganico: Bool?
    let contieneGluten: Bool?
}

struct OpenFoodFactsMetadata: Codable, Hashable {
    let source: LectorEtiquetasDataSource
    let productName: String
    let barcode: String
    let allergens: String
    let ingredientsTranslated: [String]
    let allFields: [OpenFoodFactsFieldItem]
    let nutrimentsFormatted: [OpenFoodFactsNutrimentItem]
    let ecologicalData: OpenFoodFactsEcologicalData
    let dietaryProfile: EtiquetaPerfilAlimentario?
}

struct ResultadoAnalisisEtiqueta: Codable {
    let textoDetectado: String
    let ingredientesDetectados: [String]
    let nutrientesDetectados: [NutrienteEtiqueta]
    let hallazgos: [HallazgoRiesgoEtiqueta]
    let nivelGeneral: NivelRiesgoEtiqueta
    let metadata: OpenFoodFactsMetadata?
}

struct EtiquetaParseResult {
    let originalText: String
    let ingredientes: [String]
    let nutrientes: [NutrienteEtiqueta]
    let baseDetectada: BaseMedicionEtiqueta
}

struct EtiquetaNutrienteClave: Identifiable, Hashable {
    let id: String
    let titulo: String
    let valor: String
}

enum EstadoEcologicoEtiqueta: String, Codable, Hashable {
    case confirmado
    case probable
    case noConfirmado

    var titulo: String {
        switch self {
        case .confirmado: return "Confirmado"
        case .probable: return "Probable"
        case .noConfirmado: return "No confirmado"
        }
    }
}

struct EtiquetaEvaluacionEcologica: Codable, Hashable {
    let estado: EstadoEcologicoEtiqueta
    let regionDetectada: String
    let resumen: String
    let evidencias: [String]
}

struct EtiquetaResumenProducto: Hashable {
    let nombreProducto: String
    let codigoBarras: String
    let imageURL: URL?
    let nutritionGrade: String?
    let novaGroup: Int?
    let alergenos: [String]
    let perfilAlimentario: EtiquetaPerfilAlimentario
    let aditivosDetectados: [String]
    let nutrientesClave: [EtiquetaNutrienteClave]
    let evaluacionEcologica: EtiquetaEvaluacionEcologica
}

extension ResultadoAnalisisEtiqueta {
    func resumenProducto() -> EtiquetaResumenProducto? {
        guard let metadata else { return nil }

        let nombre = metadata.productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nombreProducto = nombre.isEmpty ? "Producto sin nombre" : nombre

        return EtiquetaResumenProducto(
            nombreProducto: nombreProducto,
            codigoBarras: metadata.barcode,
            imageURL: Self.extractImageURL(from: metadata.allFields),
            nutritionGrade: Self.extractNutritionGrade(from: metadata.allFields),
            novaGroup: Self.extractNovaGroup(from: metadata.allFields),
            alergenos: Self.parseList(from: metadata.allergens),
            perfilAlimentario: metadata.dietaryProfile ?? EtiquetaPerfilAlimentario(
                esVegano: nil,
                esVegetariano: nil,
                esOrganico: nil,
                contieneGluten: nil
            ),
            aditivosDetectados: Self.parseAditivos(from: hallazgos),
            nutrientesClave: Self.extractNutrientesClave(from: metadata.nutrimentsFormatted),
            evaluacionEcologica: Self.evaluateEcologico(metadata.ecologicalData)
        )
    }

    private static func parseAditivos(from hallazgos: [HallazgoRiesgoEtiqueta]) -> [String] {
        hallazgos
            .filter { $0.categoria == .aditivoDeRiesgo }
            .map { $0.titulo.replacingOccurrences(of: "Sustancia a revisar:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .orderedUnique()
            .sorted()
    }

    private static func parseList(from rawValue: String) -> [String] {
        rawValue
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { item in
                if let idx = item.firstIndex(of: ":") {
                    let next = item.index(after: idx)
                    return String(item[next...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return item
            }
            .filter { !$0.isEmpty }
            .orderedUnique()
    }

    private static func extractNutrientesClave(from nutriments: [OpenFoodFactsNutrimentItem]) -> [EtiquetaNutrienteClave] {
        NutrienteClaveDescriptor.allCases.compactMap { descriptor in
            guard let best = bestNutriment(for: descriptor, in: nutriments) else { return nil }
            return EtiquetaNutrienteClave(id: descriptor.id, titulo: descriptor.titulo, valor: best.valueText)
        }
    }

    private static func extractImageURL(from fields: [OpenFoodFactsFieldItem]) -> URL? {
        let dictionary = Dictionary(uniqueKeysWithValues: fields.map { ($0.key, $0.value) })
        let preferredKeys = ["image_url", "image_front_url", "image_path"]

        for key in preferredKeys {
            guard let rawValue = dictionary[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !rawValue.isEmpty else { continue }
            if rawValue.hasPrefix("http://") || rawValue.hasPrefix("https://") {
                return URL(string: rawValue)
            }

            let normalizedPath = rawValue.hasPrefix("/") ? String(rawValue.dropFirst()) : rawValue
            return URL(string: "https://images.openfoodfacts.org/\(normalizedPath)")
        }

        return nil
    }

    private static func extractNutritionGrade(from fields: [OpenFoodFactsFieldItem]) -> String? {
        let dictionary = Dictionary(uniqueKeysWithValues: fields.map { ($0.key, $0.value) })
        let raw = (dictionary["nutrition_grade"] ?? dictionary["nutriscore_grade"])?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let raw, ["a", "b", "c", "d", "e"].contains(raw) else { return nil }
        return raw.uppercased()
    }

    private static func extractNovaGroup(from fields: [OpenFoodFactsFieldItem]) -> Int? {
        let dictionary = Dictionary(uniqueKeysWithValues: fields.map { ($0.key, $0.value) })
        guard let raw = dictionary["nova_group"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              let value = Int(raw),
              (1...4).contains(value) else { return nil }
        return value
    }

    private static func bestNutriment(
        for descriptor: NutrienteClaveDescriptor,
        in nutriments: [OpenFoodFactsNutrimentItem]
    ) -> OpenFoodFactsNutrimentItem? {
        let candidates = nutriments.compactMap { item -> (item: OpenFoodFactsNutrimentItem, score: Int)? in
            let normalizedKey = normalizeNutrimentKey(item.key)
            guard let aliasIndex = descriptor.aliases.firstIndex(where: { normalizedKey.hasPrefix($0) }) else { return nil }
            let score = aliasIndex * 10 + basePriority(for: normalizedKey)
            return (item, score)
        }

        return candidates.min(by: { $0.score < $1.score })?.item
    }

    private static func basePriority(for normalizedKey: String) -> Int {
        if normalizedKey.contains("100g") || normalizedKey.contains("100ml") { return 0 }
        if normalizedKey.contains("serving") || normalizedKey.contains("porcion") { return 1 }
        if normalizedKey.contains("value") { return 2 }
        return 3
    }

    private static func normalizeNutrimentKey(_ key: String) -> String {
        key
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    private static func evaluateEcologico(_ data: OpenFoodFactsEcologicalData) -> EtiquetaEvaluacionEcologica {
        let rawSources = [
            data.labels,
            data.certifications,
            data.countries,
            data.origins,
            data.labelsTags.joined(separator: ","),
            data.certificationsTags.joined(separator: ","),
            data.originsTags.joined(separator: ",")
        ]

        let normalizedSources = rawSources
            .map { normalizeText($0) }
            .filter { !$0.isEmpty }

        let tags = (data.labelsTags + data.certificationsTags + data.countriesTags + data.originsTags)
            .map(normalizeText)

        let region = detectRegion(from: data.countriesTags)

        var score = 0
        var evidencias: [String] = []

        if region == .europa {
            if hasAny(in: tags + normalizedSources, markers: OrganicMarkers.euStrong) || containsRegex(pattern: "\\b[a-z]{2}-bio-\\d{2,3}\\b", in: normalizedSources) {
                score += 4
                evidencias.append("Certificación ecológica UE detectada")
            }

            if hasAny(in: normalizedSources, markers: OrganicMarkers.euSupportive) {
                score += 1
                evidencias.append("Leyenda compatible con norma ecológica UE")
            }
        } else {
            if hasAny(in: tags + normalizedSources, markers: OrganicMarkers.nonEuStrong) {
                score += 4
                evidencias.append("Certificación orgánica regional detectada")
            }
        }

        if hasAny(in: tags + normalizedSources, markers: OrganicMarkers.globalCertifiers) {
            score += 3
            evidencias.append("Entidad certificadora orgánica reconocida")
        }

        if hasAny(in: normalizedSources, markers: OrganicMarkers.genericClaims) {
            score += 1
            evidencias.append("Declaración de tipo orgánico/ecológico en la etiqueta")
        }

        let ecoscore = normalizeText(data.ecoscoreGrade)
        if ecoscore == "a" || ecoscore == "b" {
            score += 1
            evidencias.append("Eco-score alto (apoya perfil ambiental, no certifica orgánico)")
        }

        let estado: EstadoEcologicoEtiqueta
        if score >= 4 {
            estado = .confirmado
        } else if score >= 2 {
            estado = .probable
        } else {
            estado = .noConfirmado
        }

        let resumen: String
        switch estado {
        case .confirmado:
            resumen = "Hay evidencia suficiente para clasificarlo como ecológico según señales de certificación regional."
        case .probable:
            resumen = "Hay señales parciales de producto ecológico, pero falta evidencia robusta de certificación oficial."
        case .noConfirmado:
            resumen = "No se encontraron señales suficientes para clasificarlo como ecológico con confianza."
        }

        return EtiquetaEvaluacionEcologica(
            estado: estado,
            regionDetectada: region.displayName,
            resumen: resumen,
            evidencias: evidencias.orderedUnique()
        )
    }

    private static func detectRegion(from countriesTags: [String]) -> RegionEcologica {
        let normalizedTags = countriesTags.map(normalizeText)

        if normalizedTags.contains(where: { tag in
            guard let token = tag.split(separator: ":").last else { return false }
            return OrganicMarkers.euCountries.contains(String(token))
        }) {
            return .europa
        }

        if normalizedTags.contains(where: { $0.contains("united-states") || $0.contains("canada") || $0.contains("mexico") }) {
            return .norteamerica
        }

        if normalizedTags.contains(where: { $0.contains("japan") || $0.contains("australia") || $0.contains("new-zealand") }) {
            return .asiaPacifico
        }

        return .global
    }

    private static func hasAny(in source: [String], markers: [String]) -> Bool {
        source.contains { line in
            markers.contains { line.contains($0) }
        }
    }

    private static func containsRegex(pattern: String, in source: [String]) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return source.contains { line in
            let range = NSRange(location: 0, length: line.utf16.count)
            return regex.firstMatch(in: line, range: range) != nil
        }
    }

    private static func normalizeText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum NutrienteClaveDescriptor: CaseIterable {
    case proteinas
    case fibra
    case valorEnergetico
    case grasasSaturadas
    case azucar
    case sal

    var id: String {
        switch self {
        case .proteinas: return "proteinas"
        case .fibra: return "fibra"
        case .valorEnergetico: return "valor_energetico"
        case .grasasSaturadas: return "grasas_saturadas"
        case .azucar: return "azucar"
        case .sal: return "sal"
        }
    }

    var titulo: String {
        switch self {
        case .proteinas: return "Proteínas"
        case .fibra: return "Fibra"
        case .valorEnergetico: return "Valor energético"
        case .grasasSaturadas: return "Grasas saturadas"
        case .azucar: return "Azúcar"
        case .sal: return "Sal"
        }
    }

    var aliases: [String] {
        switch self {
        case .proteinas:
            return ["proteins", "protein"]
        case .fibra:
            return ["fiber", "fibre", "dietaryfiber"]
        case .valorEnergetico:
            return ["energykcal", "energy", "energykj"]
        case .grasasSaturadas:
            return ["saturatedfat"]
        case .azucar:
            return ["sugars", "sugar"]
        case .sal:
            return ["salt"]
        }
    }
}

private enum RegionEcologica {
    case europa
    case norteamerica
    case asiaPacifico
    case global

    var displayName: String {
        switch self {
        case .europa: return "Europa"
        case .norteamerica: return "Norteamérica"
        case .asiaPacifico: return "Asia-Pacífico"
        case .global: return "Global"
        }
    }
}

private enum OrganicMarkers {
    static let euStrong = [
        "eu organic",
        "euro leaf",
        "agriculture ue",
        "agricultura ue",
        "organic farming eu"
    ]

    static let euSupportive = [
        "agriculture ue/non ue",
        "agriculture eu/non eu",
        "agricultura ue/no ue",
        "fr-bio",
        "es-eco",
        "it-bio",
        "de-oko"
    ]

    static let nonEuStrong = [
        "usda organic",
        "canada organic",
        "jas organic",
        "australian certified organic",
        "nasaa organic",
        "bio gro new zealand",
        "organic trust"
    ]

    static let globalCertifiers = [
        "ecocert",
        "soil association organic",
        "bio suisse",
        "demeter",
        "ab agriculture biologique"
    ]

    static let genericClaims = [
        "organic",
        "bio",
        "ecologico",
        "biologique"
    ]

    static let euCountries: Set<String> = [
        "austria", "belgium", "bulgaria", "croatia", "cyprus", "czech-republic", "denmark",
        "estonia", "finland", "france", "germany", "greece", "hungary", "ireland", "italy",
        "latvia", "lithuania", "luxembourg", "malta", "netherlands", "poland", "portugal",
        "romania", "slovakia", "slovenia", "spain", "sweden"
    ]
}

private extension Array where Element: Hashable {
    func orderedUnique() -> [Element] {
        var seen: Set<Element> = []
        return self.filter { seen.insert($0).inserted }
    }
}
