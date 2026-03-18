#if canImport(Testing)
import Testing

@Test("Caso 1 - pechuga de pollo")
func testChickenBreastCase() throws {
    let scorer = FoodScorer()
    let result = try scorer.score(
        FoodNutritionInput(
            protein: 23,
            saturatedFat: 1.0,
            fiber: 0,
            sugar: 0,
            salt: 0.2,
            kcal: 120
        )
    )

    #expect(result.proteinScore == 10)
    #expect(result.saturatedFatScore == 8)
    #expect(result.fiberScore == 1)
    #expect(result.sugarScore == 10)
    #expect(result.saltScore == 9)
    #expect(result.kcalScore == 8)
    #expect(result.totalScore == 7.5)
    #expect(result.calorieLabel == "poco calórico")
}

@Test("Caso 2 - galletas azucaradas")
func testSugaryCookiesCase() throws {
    let scorer = FoodScorer()
    let result = try scorer.score(
        FoodNutritionInput(
            protein: 5,
            saturatedFat: 7,
            fiber: 2,
            sugar: 25,
            salt: 0.8,
            kcal: 480
        )
    )

    #expect(result.proteinScore == 3)
    #expect(result.saturatedFatScore == 3)
    #expect(result.fiberScore == 5)
    #expect(result.sugarScore == 0)
    #expect(result.saltScore == 5)
    #expect(result.kcalScore == 2)
    #expect(result.totalScore == 3.2)
    #expect(result.calorieLabel == "calórico")
}

@Test("Caso 3 - lentejas cocidas")
func testCookedLentilsCase() throws {
    let scorer = FoodScorer()
    let result = try scorer.score(
        FoodNutritionInput(
            protein: 9,
            saturatedFat: 0.2,
            fiber: 8,
            sugar: 1.5,
            salt: 0.02,
            kcal: 116
        )
    )

    #expect(result.proteinScore == 5)
    #expect(result.saturatedFatScore == 10)
    #expect(result.fiberScore == 10)
    #expect(result.sugarScore == 10)
    #expect(result.saltScore == 10)
    #expect(result.kcalScore == 8)
    #expect(result.totalScore == 8.8)
    #expect(result.calorieLabel == "poco calórico")
}

@Test("Caso 4 - frutos secos")
func testNutsCase() throws {
    let scorer = FoodScorer()
    let result = try scorer.score(
        FoodNutritionInput(
            protein: 20,
            saturatedFat: 4.5,
            fiber: 9,
            sugar: 4,
            salt: 0.01,
            kcal: 620
        )
    )

    #expect(result.proteinScore == 10)
    #expect(result.saturatedFatScore == 6)
    #expect(result.fiberScore == 10)
    #expect(result.sugarScore == 8)
    #expect(result.saltScore == 10)
    #expect(result.kcalScore == 0)
    #expect(result.totalScore == 7.9)
    #expect(result.calorieLabel == "muy calórico")
}

@Test("Valores negativos devuelven error")
func testNegativeInputThrows() {
    let scorer = FoodScorer()

    #expect(throws: FoodScorerError.negativeValue(component: "protein")) {
        try scorer.score(
            FoodNutritionInput(
                protein: -1,
                saturatedFat: 0,
                fiber: 0,
                sugar: 0,
                salt: 0,
                kcal: 0
            )
        )
    }
}
#endif
