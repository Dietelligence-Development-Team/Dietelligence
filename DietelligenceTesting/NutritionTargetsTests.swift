//
//  NutritionTargetsTests.swift
//  DietelligenceTesting
//
//  Tests for NutritionTargets model validation logic
//

import XCTest
@testable import Dietelligence

final class NutritionTargetsTests: XCTestCase {

    // MARK: - Test Data

    var testTargets: NutritionTargets!

    override func setUp() {
        super.setUp()

        // Create standard test targets
        testTargets = NutritionTargets(
            caloriesMin: 1800,
            caloriesMax: 2200,
            caloriesTarget: 2000,
            proteinMin: 120,
            proteinMax: 160,
            proteinTarget: 140,
            fatMin: 50,
            fatMax: 80,
            fatTarget: 65,
            carbMin: 200,
            carbMax: 280,
            carbTarget: 240,
            explanation: "Test targets for weight maintenance",
            generatedDate: Date()
        )
    }

    override func tearDown() {
        testTargets = nil
        super.tearDown()
    }

    // MARK: - Calories Range Tests

    func testIsCaloriesInRange_WithinRange_ReturnsTrue() {
        // ACT
        let result = testTargets.isCaloriesInRange(2000)

        // ASSERT
        XCTAssertTrue(result, "Calories at target should be in range")
    }

    func testIsCaloriesInRange_BelowMinimum_ReturnsFalse() {
        // ACT
        let result = testTargets.isCaloriesInRange(1500)

        // ASSERT
        XCTAssertFalse(result, "Calories below minimum should be out of range")
    }

    func testIsCaloriesInRange_AboveMaximum_ReturnsFalse() {
        // ACT
        let result = testTargets.isCaloriesInRange(2500)

        // ASSERT
        XCTAssertFalse(result, "Calories above maximum should be out of range")
    }

    func testIsCaloriesInRange_AtMinimum_ReturnsTrue() {
        // ACT
        let result = testTargets.isCaloriesInRange(1800)

        // ASSERT
        XCTAssertTrue(result, "Calories at minimum boundary should be in range")
    }

    func testIsCaloriesInRange_AtMaximum_ReturnsTrue() {
        // ACT
        let result = testTargets.isCaloriesInRange(2200)

        // ASSERT
        XCTAssertTrue(result, "Calories at maximum boundary should be in range")
    }

    // MARK: - Protein Range Tests

    func testIsProteinInRange_WithinRange_ReturnsTrue() {
        // ACT
        let result = testTargets.isProteinInRange(140)

        // ASSERT
        XCTAssertTrue(result, "Protein at target should be in range")
    }

    func testIsProteinInRange_BelowMinimum_ReturnsFalse() {
        // ACT
        let result = testTargets.isProteinInRange(100)

        // ASSERT
        XCTAssertFalse(result, "Protein below minimum should be out of range")
    }

    func testIsProteinInRange_AboveMaximum_ReturnsFalse() {
        // ACT
        let result = testTargets.isProteinInRange(180)

        // ASSERT
        XCTAssertFalse(result, "Protein above maximum should be out of range")
    }

    // MARK: - Fat Range Tests

    func testIsFatInRange_WithinRange_ReturnsTrue() {
        // ACT
        let result = testTargets.isFatInRange(65)

        // ASSERT
        XCTAssertTrue(result, "Fat at target should be in range")
    }

    func testIsFatInRange_BelowMinimum_ReturnsFalse() {
        // ACT
        let result = testTargets.isFatInRange(40)

        // ASSERT
        XCTAssertFalse(result, "Fat below minimum should be out of range")
    }

    func testIsFatInRange_AboveMaximum_ReturnsFalse() {
        // ACT
        let result = testTargets.isFatInRange(90)

        // ASSERT
        XCTAssertFalse(result, "Fat above maximum should be out of range")
    }

    // MARK: - Carbohydrate Range Tests

    func testIsCarbInRange_WithinRange_ReturnsTrue() {
        // ACT
        let result = testTargets.isCarbInRange(240)

        // ASSERT
        XCTAssertTrue(result, "Carbohydrate at target should be in range")
    }

    func testIsCarbInRange_BelowMinimum_ReturnsFalse() {
        // ACT
        let result = testTargets.isCarbInRange(150)

        // ASSERT
        XCTAssertFalse(result, "Carbohydrate below minimum should be out of range")
    }

    func testIsCarbInRange_AboveMaximum_ReturnsFalse() {
        // ACT
        let result = testTargets.isCarbInRange(300)

        // ASSERT
        XCTAssertFalse(result, "Carbohydrate above maximum should be out of range")
    }

    // MARK: - All Nutrients Range Tests

    func testIsAllNutrientsInRange_AllWithinRange_ReturnsTrue() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 2000,
            protein: 140,
            fat: 65,
            carb: 240
        )

        // ASSERT
        XCTAssertTrue(result, "All nutrients at target should be in range")
    }

    func testIsAllNutrientsInRange_CaloriesOutOfRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 2500, // Out of range
            protein: 140,
            fat: 65,
            carb: 240
        )

        // ASSERT
        XCTAssertFalse(result, "Should return false if calories out of range")
    }

    func testIsAllNutrientsInRange_ProteinOutOfRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 2000,
            protein: 100, // Out of range
            fat: 65,
            carb: 240
        )

        // ASSERT
        XCTAssertFalse(result, "Should return false if protein out of range")
    }

    func testIsAllNutrientsInRange_FatOutOfRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 2000,
            protein: 140,
            fat: 100, // Out of range
            carb: 240
        )

        // ASSERT
        XCTAssertFalse(result, "Should return false if fat out of range")
    }

    func testIsAllNutrientsInRange_CarbOutOfRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 2000,
            protein: 140,
            fat: 65,
            carb: 350 // Out of range
        )

        // ASSERT
        XCTAssertFalse(result, "Should return false if carbohydrate out of range")
    }

    func testIsAllNutrientsInRange_MultipleOutOfRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 1500, // Out of range
            protein: 100,   // Out of range
            fat: 65,
            carb: 240
        )

        // ASSERT
        XCTAssertFalse(result, "Should return false if multiple nutrients out of range")
    }

    func testIsAllNutrientsInRange_AllAtBoundaries_ReturnsTrue() {
        // ACT
        let result = testTargets.isAllNutrientsInRange(
            calories: 1800, // At minimum
            protein: 160,   // At maximum
            fat: 50,        // At minimum
            carb: 280       // At maximum
        )

        // ASSERT
        XCTAssertTrue(result, "All nutrients at boundaries should be in range")
    }

    // MARK: - Codable Tests

    func testCodableEncoding_ValidTargets_EncodesCorrectly() throws {
        // ACT
        let encoded = try JSONEncoder().encode(testTargets)
        let decoded = try JSONDecoder().decode(NutritionTargets.self, from: encoded)

        // ASSERT
        XCTAssertEqual(decoded.caloriesMin, testTargets.caloriesMin)
        XCTAssertEqual(decoded.caloriesMax, testTargets.caloriesMax)
        XCTAssertEqual(decoded.caloriesTarget, testTargets.caloriesTarget)
        XCTAssertEqual(decoded.proteinMin, testTargets.proteinMin)
        XCTAssertEqual(decoded.fatMin, testTargets.fatMin)
        XCTAssertEqual(decoded.carbMin, testTargets.carbMin)
        XCTAssertEqual(decoded.explanation, testTargets.explanation)
    }

    // MARK: - Edge Cases

    func testZeroValues_ReturnsCorrectResults() {
        // ARRANGE
        let zeroTargets = NutritionTargets(
            caloriesMin: 0,
            caloriesMax: 0,
            caloriesTarget: 0,
            proteinMin: 0,
            proteinMax: 0,
            proteinTarget: 0,
            fatMin: 0,
            fatMax: 0,
            fatTarget: 0,
            carbMin: 0,
            carbMax: 0,
            carbTarget: 0,
            explanation: "Zero targets",
            generatedDate: Date()
        )

        // ACT
        let result = zeroTargets.isAllNutrientsInRange(
            calories: 0,
            protein: 0,
            fat: 0,
            carb: 0
        )

        // ASSERT
        XCTAssertTrue(result, "Zero values should match zero targets")
    }

    func testNegativeValues_BelowRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isCaloriesInRange(-100)

        // ASSERT
        XCTAssertFalse(result, "Negative values should be out of range")
    }

    func testVeryLargeValues_AboveRange_ReturnsFalse() {
        // ACT
        let result = testTargets.isCaloriesInRange(10000)

        // ASSERT
        XCTAssertFalse(result, "Very large values should be out of range")
    }
}
