//
//  GeminiNutritionPlannerTests.swift
//  DietelligenceTesting
//
//  Tests for GeminiNutritionPlanner JSON parsing and error handling
//

import XCTest
@testable import Dietelligence

final class GeminiNutritionPlannerTests: XCTestCase {

    var planner: GeminiNutritionPlanner!
    var testProfile: Dietelligence.UserNutritionProfile!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        planner = GeminiNutritionPlanner(apiKey: "test-api-key")
        testProfile = TestHelpers.createMockUserProfile()
    }

    override func tearDown() {
        planner = nil
        testProfile = nil
        super.tearDown()
    }

    // MARK: - JSON Response Parsing Tests

    func testParseResponse_ValidJSON_ReturnsNutritionTargetsResult() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200,
                "target": 2000
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": "Based on your profile, these targets will help you maintain your current weight while supporting muscle growth."
        }
        """

        // ACT
        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)

        // ASSERT
        XCTAssertEqual(result.dailyCalories.min, 1800)
        XCTAssertEqual(result.dailyCalories.max, 2200)
        XCTAssertEqual(result.dailyCalories.target, 2000)
        XCTAssertEqual(result.dailyProtein.min, 120)
        XCTAssertEqual(result.dailyProtein.max, 160)
        XCTAssertEqual(result.dailyProtein.target, 140)
        XCTAssertEqual(result.dailyFat.min, 50)
        XCTAssertEqual(result.dailyFat.max, 80)
        XCTAssertEqual(result.dailyFat.target, 65)
        XCTAssertEqual(result.dailyCarbohydrate.min, 200)
        XCTAssertEqual(result.dailyCarbohydrate.max, 280)
        XCTAssertEqual(result.dailyCarbohydrate.target, 240)
        XCTAssertFalse(result.explanation.isEmpty)
    }

    func testParseResponse_MissingField_ThrowsDecodingError() {
        // ARRANGE - Missing daily_protein field
        let invalidJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200,
                "target": 2000
            }
        }
        """

        // ACT & ASSERT
        let data = invalidJSON.data(using: .utf8)!
        XCTAssertThrowsError(
            try JSONDecoder().decode(NutritionTargetsResult.self, from: data),
            "Missing required fields should throw decoding error"
        )
    }

    func testParseResponse_InvalidDataType_ThrowsDecodingError() {
        // ARRANGE - daily_calories min is a string instead of number
        let invalidJSON = """
        {
            "daily_calories": {
                "min": "not a number",
                "max": 2200,
                "target": 2000
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": "Test"
        }
        """

        // ACT & ASSERT
        let data = invalidJSON.data(using: .utf8)!
        XCTAssertThrowsError(
            try JSONDecoder().decode(NutritionTargetsResult.self, from: data),
            "Invalid data type should throw decoding error"
        )
    }

    func testParseResponse_MissingNutrientRangeField_ThrowsDecodingError() {
        // ARRANGE - daily_calories missing "target" field
        let invalidJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": "Test"
        }
        """

        // ACT & ASSERT
        let data = invalidJSON.data(using: .utf8)!
        XCTAssertThrowsError(
            try JSONDecoder().decode(NutritionTargetsResult.self, from: data),
            "Missing nutrient range field should throw decoding error"
        )
    }

    // MARK: - NutrientRange Tests

    func testNutrientRange_ValidJSON_DecodesCorrectly() throws {
        // ARRANGE
        let validJSON = """
        {
            "min": 100,
            "max": 200,
            "target": 150
        }
        """

        // ACT
        let data = validJSON.data(using: .utf8)!
        let range = try JSONDecoder().decode(NutrientRange.self, from: data)

        // ASSERT
        XCTAssertEqual(range.min, 100)
        XCTAssertEqual(range.max, 200)
        XCTAssertEqual(range.target, 150)
    }

    // MARK: - NutritionTargets Conversion Tests

    func testInitFromResult_ValidResult_CreatesNutritionTargets() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200,
                "target": 2000
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": "Test explanation"
        }
        """

        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)

        // ACT
        let targets = NutritionTargets(from: result)

        // ASSERT
        XCTAssertEqual(targets.caloriesMin, 1800)
        XCTAssertEqual(targets.caloriesMax, 2200)
        XCTAssertEqual(targets.caloriesTarget, 2000)
        XCTAssertEqual(targets.proteinMin, 120)
        XCTAssertEqual(targets.proteinMax, 160)
        XCTAssertEqual(targets.proteinTarget, 140)
        XCTAssertEqual(targets.fatMin, 50)
        XCTAssertEqual(targets.fatMax, 80)
        XCTAssertEqual(targets.fatTarget, 65)
        XCTAssertEqual(targets.carbMin, 200)
        XCTAssertEqual(targets.carbMax, 280)
        XCTAssertEqual(targets.carbTarget, 240)
        XCTAssertEqual(targets.explanation, "Test explanation")
        XCTAssertNotNil(targets.generatedDate)
    }

    // MARK: - Error Handling Tests

    func testNutritionPlannerError_ErrorDescription_ReturnsCorrectMessage() {
        // ACT & ASSERT
        let error1 = NutritionPlannerError.invalidURL
        let error2 = NutritionPlannerError.invalidProfile
        let error3 = NutritionPlannerError.requestFailed
        let error4 = NutritionPlannerError.noValidResponse
        let error5 = NutritionPlannerError.invalidJSON
        let error6 = NutritionPlannerError.apiError(message: "Test error")

        XCTAssertEqual(error1.errorDescription, "Invalid URL")
        XCTAssertEqual(error2.errorDescription, "Invalid user profile data (weight, height, or age is invalid)")
        XCTAssertEqual(error3.errorDescription, "Request failed")
        XCTAssertEqual(error4.errorDescription, "No valid response received from Gemini API")
        XCTAssertEqual(error5.errorDescription, "Invalid JSON response")
        XCTAssertEqual(error6.errorDescription, "Gemini API Error: Test error")
    }

    // MARK: - Edge Cases

    func testParseResponse_EmptyExplanation_DecodesSuccessfully() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200,
                "target": 2000
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": ""
        }
        """

        // ACT
        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)

        // ASSERT
        XCTAssertEqual(result.explanation, "")
    }

    func testParseResponse_ZeroValues_DecodesSuccessfully() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 0,
                "max": 0,
                "target": 0
            },
            "daily_protein": {
                "min": 0,
                "max": 0,
                "target": 0
            },
            "daily_fat": {
                "min": 0,
                "max": 0,
                "target": 0
            },
            "daily_carbohydrate": {
                "min": 0,
                "max": 0,
                "target": 0
            },
            "explanation": "Zero values"
        }
        """

        // ACT
        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)

        // ASSERT
        XCTAssertEqual(result.dailyCalories.min, 0)
        XCTAssertEqual(result.dailyProtein.min, 0)
        XCTAssertEqual(result.dailyFat.min, 0)
        XCTAssertEqual(result.dailyCarbohydrate.min, 0)
    }

    func testParseResponse_VeryLargeValues_DecodesSuccessfully() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 10000,
                "max": 15000,
                "target": 12000
            },
            "daily_protein": {
                "min": 300,
                "max": 500,
                "target": 400
            },
            "daily_fat": {
                "min": 200,
                "max": 300,
                "target": 250
            },
            "daily_carbohydrate": {
                "min": 800,
                "max": 1200,
                "target": 1000
            },
            "explanation": "Very large values for testing"
        }
        """

        // ACT
        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)

        // ASSERT
        XCTAssertEqual(result.dailyCalories.max, 15000)
        XCTAssertEqual(result.dailyProtein.max, 500)
        XCTAssertEqual(result.dailyFat.max, 300)
        XCTAssertEqual(result.dailyCarbohydrate.max, 1200)
    }

    func testParseResponse_DecimalValues_DecodesSuccessfully() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 1850.5,
                "max": 2150.7,
                "target": 2000.3
            },
            "daily_protein": {
                "min": 125.8,
                "max": 155.2,
                "target": 140.5
            },
            "daily_fat": {
                "min": 52.3,
                "max": 77.9,
                "target": 65.1
            },
            "daily_carbohydrate": {
                "min": 205.6,
                "max": 275.4,
                "target": 240.5
            },
            "explanation": "Decimal values for precision"
        }
        """

        // ACT
        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)

        // ASSERT
        XCTAssertEqual(result.dailyCalories.min, 1850.5, accuracy: 0.1)
        XCTAssertEqual(result.dailyProtein.target, 140.5, accuracy: 0.1)
        XCTAssertEqual(result.dailyFat.max, 77.9, accuracy: 0.1)
        XCTAssertEqual(result.dailyCarbohydrate.target, 240.5, accuracy: 0.1)
    }

    // MARK: - Nutrition Targets Calculation Logic Tests

    func testNutritionTargets_RangeValidation_IsCorrect() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200,
                "target": 2000
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": "Test"
        }
        """

        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)
        let targets = NutritionTargets(from: result)

        // ASSERT
        XCTAssertLessThan(targets.caloriesMin, targets.caloriesTarget, "Min should be less than target")
        XCTAssertGreaterThan(targets.caloriesMax, targets.caloriesTarget, "Max should be greater than target")
        XCTAssertLessThan(targets.proteinMin, targets.proteinTarget)
        XCTAssertGreaterThan(targets.proteinMax, targets.proteinTarget)
        XCTAssertLessThan(targets.fatMin, targets.fatTarget)
        XCTAssertGreaterThan(targets.fatMax, targets.fatTarget)
        XCTAssertLessThan(targets.carbMin, targets.carbTarget)
        XCTAssertGreaterThan(targets.carbMax, targets.carbTarget)
    }

    func testNutritionTargets_RangeSpread_IsReasonable() throws {
        // ARRANGE
        let validJSON = """
        {
            "daily_calories": {
                "min": 1800,
                "max": 2200,
                "target": 2000
            },
            "daily_protein": {
                "min": 120,
                "max": 160,
                "target": 140
            },
            "daily_fat": {
                "min": 50,
                "max": 80,
                "target": 65
            },
            "daily_carbohydrate": {
                "min": 200,
                "max": 280,
                "target": 240
            },
            "explanation": "Test"
        }
        """

        let data = validJSON.data(using: .utf8)!
        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: data)
        let targets = NutritionTargets(from: result)

        // ASSERT - Check that ranges are reasonable (within ±20% of target)
        let caloriesRange = targets.caloriesMax - targets.caloriesMin
        XCTAssertLessThanOrEqual(caloriesRange, targets.caloriesTarget * 0.4, "Calories range should be ≤40% of target")

        let proteinRange = targets.proteinMax - targets.proteinMin
        XCTAssertLessThanOrEqual(proteinRange, targets.proteinTarget * 0.4, "Protein range should be ≤40% of target")
    }
}
