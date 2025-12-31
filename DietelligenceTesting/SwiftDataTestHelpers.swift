//
//  SwiftDataTestHelpers.swift
//  DietelligenceTesting
//
//  SwiftData utilities for creating in-memory test containers
//

import Foundation
import SwiftData
@testable import Dietelligence

enum SwiftDataTestHelpers {

    // MARK: - Container Creation

    /// Create an in-memory SwiftData container for UserProfile tests
    /// - Returns: A ModelContainer configured for in-memory storage
    static func createUserProfileContainer() -> ModelContainer {
        let schema = Schema([UserProfileEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }

    /// Create an in-memory SwiftData container for Meal persistence tests
    /// - Returns: A ModelContainer with MealEntity, DishEntity, and IngredientEntity
    static func createMealContainer() -> ModelContainer {
        let schema = Schema([
            MealEntity.self,
            DishEntity.self,
            IngredientEntity.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }

    // MARK: - Entity Creation Helpers

    /// Create a test MealEntity with sample data
    /// - Parameters:
    ///   - timestamp: The meal timestamp (default: now)
    ///   - mealType: The type of meal (default: lunch)
    /// - Returns: A fully configured MealEntity
    static func createTestMealEntity(
        timestamp: Date = Date(),
        mealType: MealType = .lunch
    ) -> MealEntity {
        let ingredient = IngredientEntity(
            name: "Test Ingredient",
            icon: "🥗",
            weight: 100,
            proteinPercent: 20,
            fatPercent: 10,
            carbohydratePercent: 30
        )

        let dish = DishEntity(
            name: "Test Dish",
            icon: "🍽️",
            ingredients: [ingredient]
        )

        return MealEntity(
            timestamp: timestamp,
            mealType: mealType,
            photo: nil,
            dishes: [dish],
            dietaryAdvice: nil
        )
    }

    /// Create a test UserProfileEntity with sample data
    /// - Returns: A fully configured UserProfileEntity
    static func createTestUserProfileEntity() -> UserProfileEntity {
        let profile = Dietelligence.UserNutritionProfile(
            name: "Test User",
            weight: 70,
            height: 175,
            age: 30,
            gender: "Male",
            activityLevel: "Moderate",
            goals: ["Maintain weight"],
            preference: "No preference",
            other: "N/A"
        )
        return UserProfileEntity(profile: profile)
    }
}
