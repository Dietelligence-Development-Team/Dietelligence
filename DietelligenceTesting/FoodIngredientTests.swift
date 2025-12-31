//
//  FoodIngredientTests.swift
//  DietelligenceTesting
//
//  Tests for FoodIngredient nutrient calculations and calorie formula
//

import XCTest
@testable import Dietelligence

final class FoodIngredientTests: XCTestCase {

    // MARK: - Weight Calculation Tests

    /// Test protein weight calculation
    func testProteinWeight_ValidPercent_CalculatesCorrectly() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Chicken",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,
            fatPercent: 3.6,
            carbohydratePercent: 0
        )

        // ACT
        let proteinWeight = ingredient.proteinWeight

        // ASSERT
        // 150g * 31% = 150 * 31 / 100 = 46.5g
        XCTAssertEqual(proteinWeight, 46.5, accuracy: 0.01, "Protein weight should be weight * percent / 100")
    }

    /// Test fat weight calculation
    func testFatWeight_ValidPercent_CalculatesCorrectly() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Avocado",
            icon: "🥑",
            weight: 100,
            proteinPercent: 2,
            fatPercent: 15,
            carbohydratePercent: 9
        )

        // ACT
        let fatWeight = ingredient.fatWeight

        // ASSERT
        // 100g * 15% = 15g
        XCTAssertEqual(fatWeight, 15.0, accuracy: 0.01, "Fat weight should be weight * percent / 100")
    }

    /// Test carbohydrate weight calculation
    func testCarbohydrateWeight_ValidPercent_CalculatesCorrectly() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Rice",
            icon: "🍚",
            weight: 150,
            proteinPercent: 2.6,
            fatPercent: 0.3,
            carbohydratePercent: 25.9
        )

        // ACT
        let carbWeight = ingredient.carbohydrateWeight

        // ASSERT
        // 150g * 25.9% = 150 * 25.9 / 100 = 38.85g
        XCTAssertEqual(carbWeight, 38.85, accuracy: 0.01, "Carbohydrate weight should be weight * percent / 100")
    }

    // MARK: - Calorie Calculation Tests

    /// Test calories with only protein (4 cal/g)
    func testCalories_OnlyProtein_Returns4CalPerGram() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Pure Protein",
            icon: "🥩",
            weight: 100,
            proteinPercent: 20,  // 20g protein
            fatPercent: 0,
            carbohydratePercent: 0
        )

        // ACT
        let calories = ingredient.calories

        // ASSERT
        // 20g protein * 4 cal/g = 80 calories
        XCTAssertEqual(calories, 80, accuracy: 0.01, "Protein should contribute 4 calories per gram")
    }

    /// Test calories with only fat (9 cal/g)
    func testCalories_OnlyFat_Returns9CalPerGram() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Pure Fat",
            icon: "🧈",
            weight: 100,
            proteinPercent: 0,
            fatPercent: 10,  // 10g fat
            carbohydratePercent: 0
        )

        // ACT
        let calories = ingredient.calories

        // ASSERT
        // 10g fat * 9 cal/g = 90 calories
        XCTAssertEqual(calories, 90, accuracy: 0.01, "Fat should contribute 9 calories per gram")
    }

    /// Test calories with only carbohydrates (4 cal/g)
    func testCalories_OnlyCarbs_Returns4CalPerGram() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Pure Carbs",
            icon: "🍞",
            weight: 100,
            proteinPercent: 0,
            fatPercent: 0,
            carbohydratePercent: 25  // 25g carbs
        )

        // ACT
        let calories = ingredient.calories

        // ASSERT
        // 25g carbs * 4 cal/g = 100 calories
        XCTAssertEqual(calories, 100, accuracy: 0.01, "Carbohydrates should contribute 4 calories per gram")
    }

    /// Test calories with mixed nutrients
    func testCalories_MixedNutrients_CalculatesCorrectTotal() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Mixed Food",
            icon: "🍽️",
            weight: 100,
            proteinPercent: 20,  // 20g protein
            fatPercent: 10,      // 10g fat
            carbohydratePercent: 30  // 30g carbs
        )

        // ACT
        let calories = ingredient.calories

        // ASSERT
        // (20g * 4) + (10g * 9) + (30g * 4) = 80 + 90 + 120 = 290 calories
        XCTAssertEqual(calories, 290, accuracy: 0.01, "Total calories should be sum of all macronutrients")
    }

    // MARK: - Edge Cases

    /// Test calculations with zero weight
    func testCalculations_ZeroWeight_ReturnsZero() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Empty",
            icon: "⚪",
            weight: 0,
            proteinPercent: 20,
            fatPercent: 10,
            carbohydratePercent: 30
        )

        // ACT & ASSERT
        XCTAssertEqual(ingredient.proteinWeight, 0, "Zero weight should result in zero protein")
        XCTAssertEqual(ingredient.fatWeight, 0, "Zero weight should result in zero fat")
        XCTAssertEqual(ingredient.carbohydrateWeight, 0, "Zero weight should result in zero carbs")
        XCTAssertEqual(ingredient.calories, 0, "Zero weight should result in zero calories")
    }

    /// Test calculations with zero percentages
    func testCalculations_ZeroPercent_ReturnsZero() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "No Nutrients",
            icon: "💧",
            weight: 100,
            proteinPercent: 0,
            fatPercent: 0,
            carbohydratePercent: 0
        )

        // ACT & ASSERT
        XCTAssertEqual(ingredient.proteinWeight, 0, "Zero percent should result in zero weight")
        XCTAssertEqual(ingredient.fatWeight, 0, "Zero percent should result in zero weight")
        XCTAssertEqual(ingredient.carbohydrateWeight, 0, "Zero percent should result in zero weight")
        XCTAssertEqual(ingredient.calories, 0, "Zero nutrients should result in zero calories")
    }

    /// Test available property sums all percentages
    func testAvailable_AllNutrients_SumsPercents() {
        // ARRANGE
        let ingredient = FoodIngredient(
            name: "Test Food",
            icon: "🍔",
            weight: 100,
            proteinPercent: 25,
            fatPercent: 15,
            carbohydratePercent: 40
        )

        // ACT
        let available = ingredient.available

        // ASSERT
        // 25 + 15 + 40 = 80
        XCTAssertEqual(available, 80, accuracy: 0.01, "Available should sum all nutrient percentages")
    }

    // MARK: - Realistic Food Examples

    /// Test with realistic chicken breast values
    func testCalories_ChickenBreast_CalculatesRealisticValues() {
        // ARRANGE
        let chicken = FoodIngredient(
            name: "Chicken Breast",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,
            fatPercent: 3.6,
            carbohydratePercent: 0
        )

        // ACT
        let calories = chicken.calories

        // ASSERT
        // Protein: 150 * 31 / 100 = 46.5g * 4 = 186 cal
        // Fat: 150 * 3.6 / 100 = 5.4g * 9 = 48.6 cal
        // Total: 234.6 cal
        XCTAssertEqual(calories, 234.6, accuracy: 0.1, "Chicken breast calories should match realistic values")
    }

    /// Test with realistic broccoli values
    func testCalories_Broccoli_CalculatesRealisticValues() {
        // ARRANGE
        let broccoli = FoodIngredient(
            name: "Broccoli",
            icon: "🥦",
            weight: 100,
            proteinPercent: 2.8,
            fatPercent: 0.4,
            carbohydratePercent: 7
        )

        // ACT
        let calories = broccoli.calories

        // ASSERT
        // Protein: 100 * 2.8 / 100 = 2.8g * 4 = 11.2 cal
        // Fat: 100 * 0.4 / 100 = 0.4g * 9 = 3.6 cal
        // Carbs: 100 * 7 / 100 = 7g * 4 = 28 cal
        // Total: 42.8 cal
        XCTAssertEqual(calories, 42.8, accuracy: 0.1, "Broccoli calories should match realistic values")
    }
}
