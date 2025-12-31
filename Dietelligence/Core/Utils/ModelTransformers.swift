//
//  ModelTransformers.swift
//  Dietelligence
//
//  Data transformation layer between API models and UI models
//

import UIKit
import Foundation

enum TransformError: Error, LocalizedError {
    case imageConversionFailed
    case imageOptimizationFailed
    case noFoodDetected

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG format"
        case .imageOptimizationFailed:
            return "Failed to optimize image for upload"
        case .noFoodDetected:
            return "No food detected in the image. Please try again with a clearer photo."
        }
    }
}

struct ModelTransformers {

    // MARK: - Image Processing

    /// Save UIImage to temporary file for API upload
    /// - Parameter image: The UIImage to save
    /// - Returns: URL of the saved temporary file
    /// - Throws: TransformError if conversion or save fails
    static func saveImageToTempFile(_ image: UIImage) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "food_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(filename)

        // Optimize image before saving
        let optimized = optimizeImageForUpload(image)

        guard let data = optimized.jpegData(compressionQuality: 0.8) else {
            throw TransformError.imageConversionFailed
        }

        try data.write(to: fileURL)
        return fileURL
    }

    /// Optimize image size for API upload
    /// Resizes to maximum 1024x1024 while maintaining aspect ratio
    /// - Parameter image: Original UIImage
    /// - Returns: Optimized UIImage
    static func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024

        // Calculate scale to fit within max dimension
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)

        // If already small enough, return original
        if scale >= 1.0 {
            return image
        }

        // Calculate new size
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        // Render resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - API Model → UI Model Transformations

    /// Transform Gemini API FoodAnalysisResult to UI Dish models
    /// - Parameter result: FoodAnalysisResult from Gemini API
    /// - Returns: Array of Dish models for UI display
    static func transformToDishes(_ result: FoodAnalysisResult) -> [Dish] {
        return result.dishes.map { foodDish in
            Dish(
                name: foodDish.dishName,
                icon: firstIcon(from: foodDish.icon),
                ingredients: foodDish.ingredients.map { ingredient in
                    FoodIngredient(
                        name: ingredient.name,
                        icon: firstIcon(from: ingredient.icon),
                        weight: ingredient.weight,
                        proteinPercent: ingredient.proteinPercent,
                        fatPercent: ingredient.fatPercent,
                        carbohydratePercent: ingredient.carbohydratePercent
                    )
                }
            )
        }
    }

    /// Normalize icon strings to the first emoji/character (Gemini may return multiple)
    private static func firstIcon(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "" }
        return String(first)
    }

    /// Create DietaryAdviceInput from analysis result and user profile
    /// - Parameters:
    ///   - analysis: FoodAnalysisResult from food analysis API
    ///   - userProfile: User's nutrition profile
    /// - Returns: DietaryAdviceInput for dietary advisor API
    static func createDietaryAdviceInput(
        from analysis: FoodAnalysisResult,
        userProfile: UserNutritionProfile
    ) -> DietaryAdviceInput {
        // Calculate current meal stats
        let currentStats = calculateCurrentMealStats(from: analysis)

        // Get nutrition average from SwiftData (returns nil if no history)
        let nutritionAvg = getNutritionAverage()

        // Determine meal kind based on time
        let mealKind = determineMealKind()

        // Current timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())

        // Transform dishes to MealDish format
        let dishes: [MealDish] = analysis.dishes.map { dish in
            MealDish(
                name: dish.dishName,
                ingredients: dish.ingredients.map { ingredient in
                    BasicIngredient(name: ingredient.name, weight: ingredient.weight)
                }
            )
        }

        return DietaryAdviceInput(
            kind: mealKind,
            timestamp: timestamp,
            dishes: dishes,
            currentMealStats: currentStats,
            nutritionAverage: nutritionAvg,
            userProfile: userProfile
        )
    }

    // MARK: - Helper Methods

    /// Calculate current meal nutrition statistics
    private static func calculateCurrentMealStats(from analysis: FoodAnalysisResult) -> CurrentMealStats {
        var totalCalories: Double = 0
        var totalWeight: Double = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        var totalCarbs: Double = 0

        for dish in analysis.dishes {
            for ingredient in dish.ingredients {
                // Calculate absolute nutrient weights
                let protein = ingredient.weight * ingredient.proteinPercent / 100
                let fat = ingredient.weight * ingredient.fatPercent / 100
                let carbs = ingredient.weight * ingredient.carbohydratePercent / 100

                // Calories: protein 4 kcal/g, fat 9 kcal/g, carbs 4 kcal/g
                let calories = (protein * 4) + (fat * 9) + (carbs * 4)

                totalCalories += calories
                totalWeight += ingredient.weight
                totalProtein += protein
                totalFat += fat
                totalCarbs += carbs
            }
        }

        return CurrentMealStats(
            totalcalories: totalCalories,
            totalweight: totalWeight,
            totalprotein: totalProtein,
            totalfat: totalFat,
            totalcarbohydrate: totalCarbs
        )
    }

    /// Determine meal kind based on current time
    private static func determineMealKind() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<10:
            return "Breakfast"
        case 10..<15:
            return "Lunch"
        case 15..<22:
            return "Dinner"
        default:
            return "Snack"
        }
    }

    /// Calculate nutrition average from SwiftData MealEntity records
    /// Returns nil if no meal history exists
    /// Uses up to 3 days of data (or whatever is available)
    private static func getNutritionAverage() -> NutritionAverage? {
        // Get current date bounds
        let now = Date()
        let calendar = Calendar.current

        // Calculate 3 days ago (start of day)
        guard let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now),
              let startOfPeriod = calendar.startOfDay(for: threeDaysAgo) as Date? else {
            return nil
        }

        // Fetch meals from last 3 days using SwiftData
        let meals = MealPersistenceManager.shared.fetchMeals(from: startOfPeriod, to: now)

        // Return nil if no history
        guard !meals.isEmpty else {
            return nil
        }

        // Calculate totals
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        var totalCarbs: Double = 0

        for meal in meals {
            totalCalories += meal.totalCalories
            totalProtein += meal.totalProtein
            totalFat += meal.totalFat
            totalCarbs += meal.totalCarbohydrate
        }

        let mealCount = meals.count

        // Calculate averages per meal
        let avgCalories = totalCalories / Double(mealCount)
        let avgProtein = totalProtein / Double(mealCount)
        let avgFat = totalFat / Double(mealCount)
        let avgCarbs = totalCarbs / Double(mealCount)

        // Calculate actual days covered
        let oldestMeal = meals.map { $0.timestamp }.min() ?? now
        let daysCovered = max(1, calendar.dateComponents([.day], from: oldestMeal, to: now).day ?? 1)

        return NutritionAverage(
            calories: avgCalories,
            protein: avgProtein,
            fat: avgFat,
            carbs: avgCarbs,
            daysCovered: min(daysCovered, 3),  // Cap at 3
            mealCount: mealCount
        )
    }

}
