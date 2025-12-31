
import XCTest
@testable import Dietelligence // Use @testable to access internal members of the app

// Disambiguate models that exist in both the app and test targets.
typealias AppFoodAnalysisResult = Dietelligence.FoodAnalysisResult
typealias AppFoodDish = Dietelligence.FoodDish
typealias AppFoodIngredientDetail = Dietelligence.FoodIngredientDetail
typealias AppUserNutritionProfile = Dietelligence.UserNutritionProfile

// After completing the "Target Membership" step for `GeminiModels.swift` in Xcode,
// the test target will have access to the real API models, and this file will compile.

final class ModelTransformersTests: XCTestCase {

    var mockAnalysisResult: AppFoodAnalysisResult!

    // This method is called before each test.
    override func setUp() {
        super.setUp()
        // ARRANGE: Create a consistent mock data object to use in tests.
        let ingredient1 = AppFoodIngredientDetail(
            name: "Chicken Breast",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,
            fatPercent: 3.6,
            carbohydratePercent: 0
        )
        let ingredient2 = AppFoodIngredientDetail(
            name: "Broccoli",
            icon: "🥦  ", // Intentionally add extra space to test trimming
            weight: 100,
            proteinPercent: 2.8,
            fatPercent: 0.4,
            carbohydratePercent: 7
        )
        let dish1 = AppFoodDish(
            dishName: "Healthy Bowl",
            icon: "🥗",
            ingredients: [ingredient1, ingredient2]
        )
        mockAnalysisResult = AppFoodAnalysisResult(dishNum: 1, dishes: [dish1])
    }

    // This method is called after each test.
    override func tearDown() {
        mockAnalysisResult = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    /// **Tests `transformToDishes` function.**
    /// It verifies that the API result is correctly transformed into UI-ready `Dish` models.
    /// It also implicitly tests the private `firstIcon` helper.
    func testTransformToDishes_CorrectlyTransformsData() {
        // ARRANGE: Mock data is already prepared in setUp()

        // ACT: Call the function we want to test.
        let dishes = ModelTransformers.transformToDishes(mockAnalysisResult!)

        // ASSERT: Check if the output is what we expect.
        XCTAssertEqual(dishes.count, 1, "Should be one dish")

        guard let firstDish = dishes.first else {
            XCTFail("Failed to get the first dish")
            return
        }

        XCTAssertEqual(firstDish.name, "Healthy Bowl")
        XCTAssertEqual(firstDish.icon, "🥗")
        XCTAssertEqual(firstDish.ingredients.count, 2, "Should be two ingredients")

        // Check the first ingredient
        let chicken = firstDish.ingredients[0]
        XCTAssertEqual(chicken.name, "Chicken Breast")
        XCTAssertEqual(chicken.icon, "🐔", "Icon should be the first character")

        // Check the second ingredient (and the trimming of its icon)
        let broccoli = firstDish.ingredients[1]
        XCTAssertEqual(broccoli.name, "Broccoli")
        XCTAssertEqual(broccoli.icon, "🥦", "Icon should be trimmed and be the first character")
        XCTAssertEqual(broccoli.weight, 100)
    }

    /// **Tests the `calculateCurrentMealStats` logic via the `createDietaryAdviceInput` function.**
    /// It verifies that the total calories, protein, fat, and carbs are calculated correctly.
    func testCreateDietaryAdviceInput_CalculatesStatsCorrectly() {
        // ARRANGE:
        // - `mockAnalysisResult` is from setUp()
        // - Create a mock user profile using the correct initializer
        let mockProfile = AppUserNutritionProfile(
            name: "Tester",
            weight: 75,
            height: 180,
            age: 30,
            gender: "Male",
            activityLevel: "Moderate",
            goals: ["Maintain weight"],
            preference: "No special preference",
            other: "N/A"
        )

        // Expected nutrition values:
        // Chicken: 150g * 31% = 46.5g protein, 150g * 3.6% = 5.4g fat
        // Broccoli: 100g * 2.8% = 2.8g protein, 100g * 0.4% = 0.4g fat, 100g * 7% = 7g carbs
        // Total Protein = 46.5 + 2.8 = 49.3g
        // Total Fat = 5.4 + 0.4 = 5.8g
        // Total Carbs = 7g
        // Total Calories = (49.3g protein * 4) + (5.8g fat * 9) + (7g carbs * 4)
        //                = 197.2 + 52.2 + 28 = 277.4 kcal

        let expectedProtein: Double = 49.3
        let expectedFat: Double = 5.8
        let expectedCarbs: Double = 7.0
        let expectedCalories: Double = 277.4

        // ACT: Call the function.
        let adviceInput = ModelTransformers.createDietaryAdviceInput(
            from: mockAnalysisResult!,
            userProfile: mockProfile
        )

        // ASSERT: Check the calculated meal stats.
        let stats = adviceInput.currentMealStats
        XCTAssertEqual(stats.totalprotein, expectedProtein, accuracy: 0.01, "Protein calculation is incorrect")
        XCTAssertEqual(stats.totalfat, expectedFat, accuracy: 0.01, "Fat calculation is incorrect")
        XCTAssertEqual(stats.totalcarbohydrate, expectedCarbs, accuracy: 0.01, "Carbs calculation is incorrect")
        XCTAssertEqual(stats.totalcalories, expectedCalories, accuracy: 0.01, "Calories calculation is incorrect")
    }

    // MARK: - Image Processing Tests

    /// Test optimizing a large image resizes to 1024x1024 max
    func testOptimizeImageForUpload_LargeImage_ResizesTo1024Max() {
        // ARRANGE
        let largeImage = TestHelpers.createLargeTestImage(size: CGSize(width: 2048, height: 2048))

        // ACT
        let optimized = ModelTransformers.optimizeImageForUpload(largeImage)

        // ASSERT
        XCTAssertEqual(optimized.size.width, 1024, accuracy: 1.0, "Width should be scaled to 1024")
        XCTAssertEqual(optimized.size.height, 1024, accuracy: 1.0, "Height should be scaled to 1024")
    }

    /// Test optimizing a small image returns original
    func testOptimizeImageForUpload_SmallImage_ReturnsOriginal() {
        // ARRANGE
        let smallImage = TestHelpers.createLargeTestImage(size: CGSize(width: 512, height: 512))

        // ACT
        let optimized = ModelTransformers.optimizeImageForUpload(smallImage)

        // ASSERT
        XCTAssertEqual(optimized.size.width, 512, accuracy: 1.0, "Small image should not be upscaled")
        XCTAssertEqual(optimized.size.height, 512, accuracy: 1.0, "Small image should not be upscaled")
    }

    /// Test optimizing a wide image maintains aspect ratio
    func testOptimizeImageForUpload_WideImage_MaintainsAspectRatio() {
        // ARRANGE
        let wideImage = TestHelpers.createLargeTestImage(size: CGSize(width: 1600, height: 900))

        // ACT
        let optimized = ModelTransformers.optimizeImageForUpload(wideImage)

        // ASSERT
        // Aspect ratio 16:9 should be maintained
        // Scale: 1024/1600 = 0.64
        // New dimensions: 1024 x 576
        XCTAssertEqual(optimized.size.width, 1024, accuracy: 1.0, "Width should be 1024")
        XCTAssertEqual(optimized.size.height, 576, accuracy: 1.0, "Height should maintain aspect ratio")
    }

    /// Test optimizing a tall image maintains aspect ratio
    func testOptimizeImageForUpload_TallImage_MaintainsAspectRatio() {
        // ARRANGE
        let tallImage = TestHelpers.createLargeTestImage(size: CGSize(width: 900, height: 1600))

        // ACT
        let optimized = ModelTransformers.optimizeImageForUpload(tallImage)

        // ASSERT
        // Scale: 1024/1600 = 0.64
        // New dimensions: 576 x 1024
        XCTAssertEqual(optimized.size.width, 576, accuracy: 1.0, "Width should maintain aspect ratio")
        XCTAssertEqual(optimized.size.height, 1024, accuracy: 1.0, "Height should be 1024")
    }

    /// Test saving image to temp file creates JPEG
    func testSaveImageToTempFile_ValidImage_CreatesJPEGFile() throws {
        // ARRANGE
        let testImage = TestHelpers.createTestImage()

        // ACT
        let fileURL = try ModelTransformers.saveImageToTempFile(testImage)

        // ASSERT
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "File should exist")
        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("food_"), "Filename should start with 'food_'")
        XCTAssertTrue(fileURL.pathExtension == "jpg", "File extension should be .jpg")

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Icon Normalization Tests

    /// Test extracting first emoji from a string
    func testIconNormalization_SingleEmoji_ReturnsEmoji() {
        // ARRANGE
        let ingredient = AppFoodIngredientDetail(
            name: "Fish",
            icon: "🐟",
            weight: 100,
            proteinPercent: 20,
            fatPercent: 5,
            carbohydratePercent: 0
        )
        let dish = AppFoodDish(dishName: "Fish Dish", icon: "🐟", ingredients: [ingredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])

        // ACT
        let transformed = ModelTransformers.transformToDishes(result)

        // ASSERT
        XCTAssertEqual(transformed.first?.icon, "🐟", "Should extract emoji correctly")
    }

    /// Test extracting first character when multiple emojis with spaces
    func testIconNormalization_WithWhitespace_TrimsAndReturnsFirst() {
        // ARRANGE
        let ingredient = AppFoodIngredientDetail(
            name: "Broccoli",
            icon: "🥦  ",  // Extra spaces
            weight: 100,
            proteinPercent: 2.8,
            fatPercent: 0.4,
            carbohydratePercent: 7
        )
        let dish = AppFoodDish(dishName: "Veggie", icon: "🥗 ", ingredients: [ingredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])

        // ACT
        let transformed = ModelTransformers.transformToDishes(result)

        // ASSERT
        XCTAssertEqual(transformed.first?.icon, "🥗", "Should trim whitespace and extract first character")
        XCTAssertEqual(transformed.first?.ingredients.first?.icon, "🥦", "Should handle ingredient icons too")
    }

    // MARK: - Edge Cases for Calculations

    /// Test calculation with zero weight ingredients
    func testCalculateStats_ZeroWeight_ReturnsZeroCalories() {
        // ARRANGE
        let zeroIngredient = AppFoodIngredientDetail(
            name: "Empty",
            icon: "⚪",
            weight: 0,
            proteinPercent: 20,
            fatPercent: 10,
            carbohydratePercent: 30
        )
        let dish = AppFoodDish(dishName: "Empty Dish", icon: "🍽️", ingredients: [zeroIngredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])
        let mockProfile = TestHelpers.createMockUserProfile()

        // ACT
        let adviceInput = ModelTransformers.createDietaryAdviceInput(from: result, userProfile: mockProfile)

        // ASSERT
        XCTAssertEqual(adviceInput.currentMealStats.totalcalories, 0, accuracy: 0.01, "Zero weight should result in zero calories")
        XCTAssertEqual(adviceInput.currentMealStats.totalprotein, 0, accuracy: 0.01, "Zero weight should result in zero protein")
    }

    /// Test calculation with only protein (4 cal/g)
    func testCalculateStats_OnlyProtein_CalculatesCorrectCalories() {
        // ARRANGE
        let proteinIngredient = AppFoodIngredientDetail(
            name: "Pure Protein",
            icon: "🥩",
            weight: 100,
            proteinPercent: 25,  // 25g protein
            fatPercent: 0,
            carbohydratePercent: 0
        )
        let dish = AppFoodDish(dishName: "Protein Dish", icon: "🥩", ingredients: [proteinIngredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])
        let mockProfile = TestHelpers.createMockUserProfile()

        // ACT
        let adviceInput = ModelTransformers.createDietaryAdviceInput(from: result, userProfile: mockProfile)

        // ASSERT
        // 25g protein * 4 cal/g = 100 calories
        XCTAssertEqual(adviceInput.currentMealStats.totalcalories, 100, accuracy: 0.01, "Protein should contribute 4 calories per gram")
    }

    /// Test calculation with only fat (9 cal/g)
    func testCalculateStats_OnlyFat_CalculatesCorrectCalories() {
        // ARRANGE
        let fatIngredient = AppFoodIngredientDetail(
            name: "Pure Fat",
            icon: "🧈",
            weight: 100,
            proteinPercent: 0,
            fatPercent: 20,  // 20g fat
            carbohydratePercent: 0
        )
        let dish = AppFoodDish(dishName: "Fat Dish", icon: "🧈", ingredients: [fatIngredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])
        let mockProfile = TestHelpers.createMockUserProfile()

        // ACT
        let adviceInput = ModelTransformers.createDietaryAdviceInput(from: result, userProfile: mockProfile)

        // ASSERT
        // 20g fat * 9 cal/g = 180 calories
        XCTAssertEqual(adviceInput.currentMealStats.totalcalories, 180, accuracy: 0.01, "Fat should contribute 9 calories per gram")
    }

    /// Test calculation with only carbs (4 cal/g)
    func testCalculateStats_OnlyCarbs_CalculatesCorrectCalories() {
        // ARRANGE
        let carbIngredient = AppFoodIngredientDetail(
            name: "Pure Carbs",
            icon: "🍞",
            weight: 100,
            proteinPercent: 0,
            fatPercent: 0,
            carbohydratePercent: 30  // 30g carbs
        )
        let dish = AppFoodDish(dishName: "Carb Dish", icon: "🍞", ingredients: [carbIngredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])
        let mockProfile = TestHelpers.createMockUserProfile()

        // ACT
        let adviceInput = ModelTransformers.createDietaryAdviceInput(from: result, userProfile: mockProfile)

        // ASSERT
        // 30g carbs * 4 cal/g = 120 calories
        XCTAssertEqual(adviceInput.currentMealStats.totalcalories, 120, accuracy: 0.01, "Carbs should contribute 4 calories per gram")
    }

    /// Test calculation with mixed nutrients
    func testCalculateStats_MixedNutrients_CalculatesCorrectly() {
        // Already covered by testCreateDietaryAdviceInput_CalculatesStatsCorrectly
        // This is a duplicate check for clarity

        // ARRANGE
        let mixedIngredient = AppFoodIngredientDetail(
            name: "Mixed Food",
            icon: "🍽️",
            weight: 100,
            proteinPercent: 20,  // 20g protein
            fatPercent: 10,      // 10g fat
            carbohydratePercent: 30  // 30g carbs
        )
        let dish = AppFoodDish(dishName: "Mixed Dish", icon: "🍽️", ingredients: [mixedIngredient])
        let result = AppFoodAnalysisResult(dishNum: 1, dishes: [dish])
        let mockProfile = TestHelpers.createMockUserProfile()

        // ACT
        let adviceInput = ModelTransformers.createDietaryAdviceInput(from: result, userProfile: mockProfile)

        // ASSERT
        // (20g * 4) + (10g * 9) + (30g * 4) = 80 + 90 + 120 = 290 calories
        XCTAssertEqual(adviceInput.currentMealStats.totalcalories, 290, accuracy: 0.01, "Mixed nutrients should calculate correctly")
        XCTAssertEqual(adviceInput.currentMealStats.totalprotein, 20, accuracy: 0.01, "Protein should be correct")
        XCTAssertEqual(adviceInput.currentMealStats.totalfat, 10, accuracy: 0.01, "Fat should be correct")
        XCTAssertEqual(adviceInput.currentMealStats.totalcarbohydrate, 30, accuracy: 0.01, "Carbs should be correct")
    }
}
