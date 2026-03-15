//
//  LectorEtiquetasService.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

final class LectorEtiquetasService: @unchecked Sendable {
    private let openFoodFactsClient: OpenFoodFactsClient
    private let riskEngine: OpenFoodFactsRiskEngine

    init(
        openFoodFactsClient: OpenFoodFactsClient = OpenFoodFactsClient(),
        riskEngine: OpenFoodFactsRiskEngine = OpenFoodFactsRiskEngine()
    ) {
        self.openFoodFactsClient = openFoodFactsClient
        self.riskEngine = riskEngine
    }

    func analizar(codigoBarras: String) async throws -> ResultadoAnalisisEtiqueta {
        let barcode = codigoBarras
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")

        guard !barcode.isEmpty,
              barcode.allSatisfy({ $0.isNumber }) else {
            throw LectorEtiquetasError.codigoBarrasInvalido
        }

        let payload = try await openFoodFactsClient.fetchProduct(by: barcode)
        var resultado = riskEngine.analyze(product: payload.product)

        let ingredientesTraducidos = translateIngredientsToSpanish(resultado.ingredientesDetectados)
        let allergens = payload.product.allergens?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let metadata = OpenFoodFactsMetadata(
            productName: payload.product.productName ?? "",
            barcode: payload.product.code ?? barcode,
            allergens: allergens,
            ingredientsTranslated: ingredientesTraducidos,
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
