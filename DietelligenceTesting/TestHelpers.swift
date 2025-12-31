//
//  TestHelpers.swift
//  DietelligenceTesting
//
//  Test utility functions for creating mock data and test images
//

import UIKit
@testable import Dietelligence

enum TestHelpers {

    // MARK: - Image Creation

    /// Create a lightweight 1x1 test image
    /// - Parameter color: The color of the image (default: red)
    /// - Returns: A 1x1 UIImage
    static func createTestImage(color: UIColor = .red) -> UIImage {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    /// Create a large test image for optimization testing
    /// - Parameter size: The desired size
    /// - Returns: A UIImage of the specified size
    static func createLargeTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    // MARK: - Mock Data Creation

    /// Create a mock FoodAnalysisResult for testing
    /// - Returns: A complete FoodAnalysisResult with realistic data
    static func createMockAnalysisResult() -> FoodAnalysisResult {
        let ingredient1 = FoodIngredientDetail(
            name: "Chicken Breast",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,
            fatPercent: 3.6,
            carbohydratePercent: 0
        )
        let ingredient2 = FoodIngredientDetail(
            name: "Broccoli",
            icon: "🥦",
            weight: 100,
            proteinPercent: 2.8,
            fatPercent: 0.4,
            carbohydratePercent: 7
        )
        let dish = FoodDish(
            dishName: "Healthy Bowl",
            icon: "🥗",
            ingredients: [ingredient1, ingredient2]
        )
        return FoodAnalysisResult(dishNum: 1, dishes: [dish])
    }

    /// Create a mock UserNutritionProfile for testing
    /// - Returns: A complete UserNutritionProfile with default test values
    static func createMockUserProfile() -> Dietelligence.UserNutritionProfile {
        return Dietelligence.UserNutritionProfile(
            name: "Test User",
            weight: 70,
            height: 175,
            age: 30,
            gender: "Male",
            activityLevel: "Moderate",
            goals: ["Maintain weight", "Build muscle"],
            preference: "No special preference",
            other: "N/A"
        )
    }

    /// Create a mock Dish for UI model testing
    /// - Returns: A Dish with multiple ingredients
    static func createMockDish() -> Dish {
        return Dish(
            name: "Test Dish",
            icon: "🍽️",
            ingredients: [
                FoodIngredient(
                    name: "Test Ingredient 1",
                    icon: "🥩",
                    weight: 100,
                    proteinPercent: 20,
                    fatPercent: 10,
                    carbohydratePercent: 5
                ),
                FoodIngredient(
                    name: "Test Ingredient 2",
                    icon: "🥬",
                    weight: 50,
                    proteinPercent: 3,
                    fatPercent: 0.5,
                    carbohydratePercent: 8
                )
            ]
        )
    }
}
