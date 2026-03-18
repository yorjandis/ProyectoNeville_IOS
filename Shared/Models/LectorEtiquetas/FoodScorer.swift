import Foundation

struct FoodNutritionInput: Equatable {
    let protein: Double
    let saturatedFat: Double
    let fiber: Double
    let sugar: Double
    let salt: Double
    let kcal: Double
}

struct FoodNutritionScore: Equatable {
    let proteinScore: Double
    let saturatedFatScore: Double
    let fiberScore: Double
    let sugarScore: Double
    let saltScore: Double
    let kcalScore: Double
    let totalScore: Double
    let calorieLabel: String
}

enum FoodScorerError: Error, Equatable {
    case negativeValue(component: String)
}

struct FoodScorer {
    private struct ScoreBand {
        let upperBound: Double?
        let score: Double
    }

    private let proteinBands: [ScoreBand] = [
        ScoreBand(upperBound: 3, score: 1),
        ScoreBand(upperBound: 6, score: 3),
        ScoreBand(upperBound: 10, score: 5),
        ScoreBand(upperBound: 15, score: 7),
        ScoreBand(upperBound: 20, score: 9),
        ScoreBand(upperBound: nil, score: 10)
    ]

    private let saturatedFatBands: [ScoreBand] = [
        ScoreBand(upperBound: 1, score: 10),
        ScoreBand(upperBound: 2, score: 8),
        ScoreBand(upperBound: 5, score: 6),
        ScoreBand(upperBound: 8, score: 3),
        ScoreBand(upperBound: 10, score: 1),
        ScoreBand(upperBound: nil, score: 0)
    ]

    private let fiberBands: [ScoreBand] = [
        ScoreBand(upperBound: 1, score: 1),
        ScoreBand(upperBound: 2, score: 3),
        ScoreBand(upperBound: 4, score: 5),
        ScoreBand(upperBound: 6, score: 7),
        ScoreBand(upperBound: 8, score: 9),
        ScoreBand(upperBound: nil, score: 10)
    ]

    private let sugarBands: [ScoreBand] = [
        ScoreBand(upperBound: 2, score: 10),
        ScoreBand(upperBound: 5, score: 8),
        ScoreBand(upperBound: 10, score: 6),
        ScoreBand(upperBound: 15, score: 4),
        ScoreBand(upperBound: 20, score: 2),
        ScoreBand(upperBound: nil, score: 0)
    ]

    private let saltBands: [ScoreBand] = [
        ScoreBand(upperBound: 0.1, score: 10),
        ScoreBand(upperBound: 0.3, score: 9),
        ScoreBand(upperBound: 0.5, score: 7),
        ScoreBand(upperBound: 1, score: 5),
        ScoreBand(upperBound: 2, score: 2),
        ScoreBand(upperBound: nil, score: 0)
    ]

    private let kcalBands: [ScoreBand] = [
        ScoreBand(upperBound: 50, score: 10),
        ScoreBand(upperBound: 100, score: 9),
        ScoreBand(upperBound: 150, score: 8),
        ScoreBand(upperBound: 250, score: 6),
        ScoreBand(upperBound: 350, score: 4),
        ScoreBand(upperBound: 500, score: 2),
        ScoreBand(upperBound: nil, score: 0)
    ]

    private let proteinWeight: Double = 0.20
    private let fiberWeight: Double = 0.20
    private let saturatedFatWeight: Double = 0.20
    private let sugarWeight: Double = 0.15
    private let saltWeight: Double = 0.15
    private let kcalWeight: Double = 0.10

    func score(_ input: FoodNutritionInput) throws -> FoodNutritionScore {
        try validateNonNegative(input)

        let proteinScore = scoreValue(input.protein, bands: proteinBands)
        let saturatedFatScore = scoreValue(input.saturatedFat, bands: saturatedFatBands)
        let fiberScore = scoreValue(input.fiber, bands: fiberBands)
        let sugarScore = scoreValue(input.sugar, bands: sugarBands)
        let saltScore = scoreValue(input.salt, bands: saltBands)
        let kcalScore = scoreValue(input.kcal, bands: kcalBands)

        let totalScoreRaw =
            (proteinScore * proteinWeight) +
            (fiberScore * fiberWeight) +
            (saturatedFatScore * saturatedFatWeight) +
            (sugarScore * sugarWeight) +
            (saltScore * saltWeight) +
            (kcalScore * kcalWeight)

        return FoodNutritionScore(
            proteinScore: proteinScore,
            saturatedFatScore: saturatedFatScore,
            fiberScore: fiberScore,
            sugarScore: sugarScore,
            saltScore: saltScore,
            kcalScore: kcalScore,
            totalScore: roundToSingleDecimal(totalScoreRaw),
            calorieLabel: calorieLabel(for: input.kcal)
        )
    }

    private func validateNonNegative(_ input: FoodNutritionInput) throws {
        if input.protein < 0 { throw FoodScorerError.negativeValue(component: "protein") }
        if input.saturatedFat < 0 { throw FoodScorerError.negativeValue(component: "saturatedFat") }
        if input.fiber < 0 { throw FoodScorerError.negativeValue(component: "fiber") }
        if input.sugar < 0 { throw FoodScorerError.negativeValue(component: "sugar") }
        if input.salt < 0 { throw FoodScorerError.negativeValue(component: "salt") }
        if input.kcal < 0 { throw FoodScorerError.negativeValue(component: "kcal") }
    }

    private func scoreValue(_ value: Double, bands: [ScoreBand]) -> Double {
        for band in bands {
            guard let upperBound = band.upperBound else { return band.score }
            if value < upperBound { return band.score }
        }
        return 0
    }

    private func roundToSingleDecimal(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private func calorieLabel(for kcal: Double) -> String {
        switch kcal {
        case ..<50:
            return "muy poco calórico"
        case ..<150:
            return "poco calórico"
        case ..<300:
            return "moderado"
        case ..<500:
            return "calórico"
        default:
            return "muy calórico"
        }
    }
}
