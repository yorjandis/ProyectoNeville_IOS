//
//  LectorEtiquetasService.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

struct OfflineProductSuggestion: Identifiable, Hashable {
    let barcode: String
    let productName: String
    let brands: String?

    var id: String { barcode }
}

final class LectorEtiquetasService: @unchecked Sendable {
    private let openFoodFactsClient: OpenFoodFactsClient
    private let riskEngine: OpenFoodFactsRiskEngine
    private let offlineDatabase: OfflineOpenFoodFactsDatabase

    init(
        openFoodFactsClient: OpenFoodFactsClient = OpenFoodFactsClient(),
        riskEngine: OpenFoodFactsRiskEngine = OpenFoodFactsRiskEngine(),
        offlineDatabase: OfflineOpenFoodFactsDatabase = OfflineOpenFoodFactsDatabase()
    ) {
        self.openFoodFactsClient = openFoodFactsClient
        self.riskEngine = riskEngine
        self.offlineDatabase = offlineDatabase
    }

    func prepareOfflineDatabase() async throws -> OfflineOpenFoodFactsDatabase.AvailabilityStatus {
        try await offlineDatabase.ensureDatabaseAvailable()
    }

    func analizar(
        codigoBarras: String,
        source: LectorEtiquetasDataSource,
        preferredOfflineDatabasePath: String? = nil
    ) async throws -> ResultadoAnalisisEtiqueta {
        let barcode = normalizedBarcode(from: codigoBarras)

        guard !barcode.isEmpty, barcode.allSatisfy(\.isNumber) else {
            throw LectorEtiquetasError.codigoBarrasInvalido
        }

        switch source {
        case .openFoodFacts:
            return try await analizarOpenFoodFacts(barcode: barcode)
        case .offlineSQLite:
            return try await analizarOffline(barcode: barcode, preferredOfflineDatabasePath: preferredOfflineDatabasePath)
        }
    }

    func buscarProductosOffline(
        nombre: String,
        preferredOfflineDatabasePath: String? = nil
    ) async throws -> [OfflineProductSuggestion] {
        let preferredURL = preferredOfflineDatabasePath.map(URL.init(fileURLWithPath:))
        let matches = try await offlineDatabase.searchProducts(byName: nombre, preferredDatabaseURL: preferredURL)
        return matches.map { OfflineProductSuggestion(barcode: $0.barcode, productName: $0.productName, brands: $0.brands) }
    }

    func contarProductosOffline(preferredOfflineDatabasePath: String?) async throws -> Int {
        let preferredURL = preferredOfflineDatabasePath.map(URL.init(fileURLWithPath:))
        return try await offlineDatabase.countProducts(preferredDatabaseURL: preferredURL)
    }

    private func analizarOpenFoodFacts(barcode: String) async throws -> ResultadoAnalisisEtiqueta {
        let payload = try await openFoodFactsClient.fetchProduct(by: barcode)
        var resultado = riskEngine.analyze(product: payload.product)

        let metadata = OpenFoodFactsMetadata(
            source: .openFoodFacts,
            productName: payload.product.productName ?? "",
            barcode: payload.product.code ?? barcode,
            allergens: payload.product.allergens?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            ingredientsTranslated: translateIngredientsToSpanish(resultado.ingredientesDetectados),
            allFields: payload.allFields,
            nutrimentsFormatted: payload.nutrimentsFormatted,
            ecologicalData: OpenFoodFactsEcologicalData(
                labels: payload.product.labels ?? "",
                labelsTags: payload.product.labelsTags ?? [],
                countries: payload.product.countries ?? "",
                countriesTags: payload.product.countriesTags ?? [],
                origins: payload.product.origins ?? "",
                originsTags: payload.product.originsTags ?? [],
                certifications: payload.product.certifications ?? "",
                certificationsTags: payload.product.certificationsTags ?? [],
                ecoscoreGrade: payload.product.ecoscoreGrade ?? ""
            ),
            dietaryProfile: nil
        )

        resultado = ResultadoAnalisisEtiqueta(
            textoDetectado: resultado.textoDetectado,
            ingredientesDetectados: resultado.ingredientesDetectados,
            nutrientesDetectados: resultado.nutrientesDetectados,
            hallazgos: resultado.hallazgos,
            nivelGeneral: resultado.nivelGeneral,
            metadata: metadata
        )

        return resultado
    }

    private func analizarOffline(
        barcode: String,
        preferredOfflineDatabasePath: String?
    ) async throws -> ResultadoAnalisisEtiqueta {
        let preferredURL = preferredOfflineDatabasePath.map(URL.init(fileURLWithPath:))
        let record = try await offlineDatabase.fetchProduct(by: barcode, preferredDatabaseURL: preferredURL)
        let product = buildOfflineProduct(from: record)
        var resultado = riskEngine.analyze(product: product)

        let metadata = OpenFoodFactsMetadata(
            source: .offlineSQLite,
            productName: record.productName,
            barcode: record.barcode,
            allergens: record.allergensText ?? "",
            ingredientsTranslated: translateIngredientsToSpanish(resultado.ingredientesDetectados),
            allFields: buildOfflineFields(from: record),
            nutrimentsFormatted: buildOfflineNutriments(from: record),
            ecologicalData: OpenFoodFactsEcologicalData(
                labels: record.isOrganic == true ? "organic" : "",
                labelsTags: record.isOrganic == true ? ["en:organic"] : [],
                countries: "",
                countriesTags: [],
                origins: "",
                originsTags: [],
                certifications: "",
                certificationsTags: [],
                ecoscoreGrade: ""
            ),
            dietaryProfile: EtiquetaPerfilAlimentario(
                esVegano: record.isVegan,
                esVegetariano: record.isVegetarian,
                esOrganico: record.isOrganic,
                contieneGluten: record.hasGluten
            )
        )

        resultado = ResultadoAnalisisEtiqueta(
            textoDetectado: resultado.textoDetectado,
            ingredientesDetectados: resultado.ingredientesDetectados,
            nutrientesDetectados: resultado.nutrientesDetectados,
            hallazgos: resultado.hallazgos,
            nivelGeneral: resultado.nivelGeneral,
            metadata: metadata
        )

        return resultado
    }

    private func buildOfflineProduct(from record: OfflineOpenFoodFactsDatabase.ProductRecord) -> OpenFoodFactsProduct {
        let ingredientsText = [record.additiveEcodes, record.allergensText, record.tracesText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return OpenFoodFactsProduct(
            code: record.barcode,
            productName: record.productName,
            ingredientsText: ingredientsText.isEmpty ? nil : ingredientsText,
            allergens: record.allergensText,
            nutriments: OpenFoodFactsNutriments(
                sugars100g: record.sugars100g,
                sugarsServing: nil,
                sugarsUnit: "g",
                salt100g: record.salt100g,
                saltServing: nil,
                saltUnit: "g",
                saturatedFat100g: record.saturatedFat100g,
                saturatedFatServing: nil,
                saturatedFatUnit: "g",
                sodium100g: nil,
                sodiumServing: nil,
                sodiumUnit: "g"
            ),
            labels: record.isOrganic == true ? "organic" : nil,
            labelsTags: record.isOrganic == true ? ["en:organic"] : nil,
            countries: nil,
            countriesTags: nil,
            origins: nil,
            originsTags: nil,
            certifications: nil,
            certificationsTags: nil,
            ecoscoreGrade: nil
        )
    }

    private func buildOfflineFields(from record: OfflineOpenFoodFactsDatabase.ProductRecord) -> [OpenFoodFactsFieldItem] {
        var fields: [OpenFoodFactsFieldItem] = [
            OpenFoodFactsFieldItem(key: "source", value: "offline_sqlite"),
            OpenFoodFactsFieldItem(key: "barcode", value: record.barcode),
            OpenFoodFactsFieldItem(key: "product_name", value: record.productName)
        ]

        appendField("brands", record.brands, into: &fields)
        appendField("quantity", record.quantity, into: &fields)
        appendField("nutrition_grade", record.nutritionGrade, into: &fields)
        appendField("nova_group", record.novaGroup.map(String.init), into: &fields)
        appendField("image_path", record.imagePath, into: &fields)
        appendField("additive_ecodes", record.additiveEcodes, into: &fields)
        appendField("allergens_text", record.allergensText, into: &fields)
        appendField("allergens_tags", record.allergensTags, into: &fields)
        appendField("traces_text", record.tracesText, into: &fields)
        appendField("traces_tags", record.tracesTags, into: &fields)
        appendField("is_vegan", boolField(record.isVegan), into: &fields)
        appendField("is_vegetarian", boolField(record.isVegetarian), into: &fields)
        appendField("is_organic", boolField(record.isOrganic), into: &fields)
        appendField("has_gluten", boolField(record.hasGluten), into: &fields)

        return fields
    }

    private func buildOfflineNutriments(from record: OfflineOpenFoodFactsDatabase.ProductRecord) -> [OpenFoodFactsNutrimentItem] {
        var items: [OpenFoodFactsNutrimentItem] = []

        appendNutriment(key: "energy-kcal_100g", title: "Valor energético (kcal/100g)", value: record.energyKcal100g, unit: "kcal", into: &items)
        appendNutriment(key: "proteins_100g", title: "Proteínas (g/100g)", value: record.proteins100g, unit: "g", into: &items)
        appendNutriment(key: "fiber_100g", title: "Fibra (g/100g)", value: record.fiber100g, unit: "g", into: &items)
        appendNutriment(key: "saturated-fat_100g", title: "Grasas saturadas (g/100g)", value: record.saturatedFat100g, unit: "g", into: &items)
        appendNutriment(key: "sugars_100g", title: "Azúcar (g/100g)", value: record.sugars100g, unit: "g", into: &items)
        appendNutriment(key: "salt_100g", title: "Sal (g/100g)", value: record.salt100g, unit: "g", into: &items)
        appendNutriment(key: "fat_100g", title: "Grasa total (g/100g)", value: record.fat100g, unit: "g", into: &items)
        appendNutriment(key: "carbohydrates_100g", title: "Carbohidratos (g/100g)", value: record.carbohydrates100g, unit: "g", into: &items)

        return items
    }

    private func appendField(_ key: String, _ value: String?, into fields: inout [OpenFoodFactsFieldItem]) {
        guard let value, !value.isEmpty else { return }
        fields.append(OpenFoodFactsFieldItem(key: key, value: value))
    }

    private func appendNutriment(
        key: String,
        title: String,
        value: Double?,
        unit: String,
        into items: inout [OpenFoodFactsNutrimentItem]
    ) {
        guard let value else { return }
        items.append(
            OpenFoodFactsNutrimentItem(
                key: key,
                displayName: title,
                valueText: "\(format(value)) \(unit)"
            )
        )
    }

    private func format(_ value: Double) -> String {
        let formatted = String(format: "%.4f", value)
        return formatted
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }

    private func boolField(_ value: Bool?) -> String? {
        guard let value else { return nil }
        return value ? "sí" : "no"
    }

    private func normalizedBarcode(from value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
    }

    private func translateIngredientsToSpanish(_ ingredients: [String]) -> [String] {
        ingredients.map { ingredient in
            var result = ingredient
            for entry in Self.ingredientTranslationMap {
                result = replaceCaseInsensitive(result, search: entry.key, replacement: entry.value)
            }
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static let ingredientTranslationMap: [(key: String, value: String)] = [
        ("sugar", "azúcar"),
        ("salt", "sal"),
        ("flour", "harina"),
        ("wheat", "trigo"),
        ("barley", "cebada"),
        ("rye", "centeno"),
        ("glucose-fructose syrup", "jarabe de glucosa-fructosa"),
        ("high fructose corn syrup", "jarabe de maíz de alta fructosa"),
        ("corn syrup", "jarabe de maíz"),
        ("sunflower oil", "aceite de girasol"),
        ("palm oil", "aceite de palma"),
        ("rapeseed oil", "aceite de colza"),
        ("soy lecithin", "lecitina de soja"),
        ("emulsifier", "emulsionante"),
        ("stabilizer", "estabilizante"),
        ("preservative", "conservante"),
        ("flavouring", "aromatizante"),
        ("flavoring", "aromatizante"),
        ("sweetener", "edulcorante"),
        ("colour", "colorante"),
        ("color", "colorante"),
        ("acid", "ácido"),
        ("citric acid", "ácido cítrico"),
        ("ascorbic acid", "ácido ascórbico"),
        ("sodium benzoate", "benzoato de sodio"),
        ("potassium sorbate", "sorbato de potasio"),
        ("monosodium glutamate", "glutamato monosódico"),
        ("maltodextrin", "maltodextrina")
    ]

    private func replaceCaseInsensitive(_ text: String, search: String, replacement: String) -> String {
        guard !search.isEmpty else { return text }
        return text.replacingOccurrences(of: search, with: replacement, options: [.caseInsensitive, .diacriticInsensitive], range: nil)
    }
}
