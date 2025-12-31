//
//  MealEntity.swift
//  Dietelligence
//
//  SwiftData models for persisting meal history
//

import Foundation
import SwiftData
import UIKit

// MARK: - Meal Types

enum MealType: String, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

// MARK: - Meal Entity

@Model
final class MealEntity {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mealType: String  // Store raw value of MealType
    var photoData: Data?  // Compressed JPEG

    // Stored as JSON
    var adviceData: Data?  // DietaryAdviceResult

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \DishEntity.meal)
    var dishes: [DishEntity]

    // MARK: - Computed Properties

    var mealTypeEnum: MealType {
        MealType(rawValue: mealType) ?? .snack
    }

    var photo: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }

    var dietaryAdvice: DietaryAdviceResult? {
        guard let data = adviceData else { return nil }
        return try? JSONDecoder().decode(DietaryAdviceResult.self, from: data)
    }

    // MARK: - Aggregated Nutrition

    var totalProtein: Double {
        dishes.reduce(0) { $0 + $1.totalProtein }
    }

    var totalFat: Double {
        dishes.reduce(0) { $0 + $1.totalFat }
    }

    var totalCarbohydrate: Double {
        dishes.reduce(0) { $0 + $1.totalCarbohydrate }
    }

    var totalCalories: Double {
        dishes.reduce(0) { $0 + $1.totalCalories }
    }

    // MARK: - Initialization

    init(
        timestamp: Date,
        mealType: MealType,
        photo: UIImage?,
        dishes: [DishEntity],
        dietaryAdvice: DietaryAdviceResult?
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.mealType = mealType.rawValue
        self.dishes = dishes

        // Compress and store photo
        if let photo = photo {
            let optimized = ModelTransformers.optimizeImageForUpload(photo)
            self.photoData = optimized.jpegData(compressionQuality: 0.7)
        }

        // Encode advice as JSON
        if let advice = dietaryAdvice {
            self.adviceData = try? JSONEncoder().encode(advice)
        }
    }
}

// MARK: - Dish Entity

@Model
final class DishEntity {
    var id: UUID
    var name: String
    var icon: String

    @Relationship(deleteRule: .cascade, inverse: \IngredientEntity.dish)
    var ingredients: [IngredientEntity]

    var meal: MealEntity?  // Parent relationship

    // MARK: - Computed Properties

    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.proteinWeight }
    }

    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fatWeight }
    }

    var totalCarbohydrate: Double {
        ingredients.reduce(0) { $0 + $1.carbohydrateWeight }
    }

    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    // MARK: - Initialization

    init(name: String, icon: String, ingredients: [IngredientEntity]) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.ingredients = ingredients
    }

    // MARK: - Transformers

    /// Convert to UI model
    func toDish() -> Dish {
        Dish(
            name: name,
            icon: icon,
            ingredients: ingredients.map { $0.toFoodIngredient() }
        )
    }
}

// MARK: - Ingredient Entity

@Model
final class IngredientEntity {
    var id: UUID
    var name: String
    var icon: String
    var weight: Double
    var proteinPercent: Double
    var fatPercent: Double
    var carbohydratePercent: Double

    var dish: DishEntity?  // Parent relationship

    // MARK: - Computed Properties

    var proteinWeight: Double {
        weight * proteinPercent / 100
    }

    var fatWeight: Double {
        weight * fatPercent / 100
    }

    var carbohydrateWeight: Double {
        weight * carbohydratePercent / 100
    }

    var calories: Double {
        proteinWeight * 4 + fatWeight * 9 + carbohydrateWeight * 4
    }

    // MARK: - Initialization

    init(
        name: String,
        icon: String,
        weight: Double,
        proteinPercent: Double,
        fatPercent: Double,
        carbohydratePercent: Double
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.weight = weight
        self.proteinPercent = proteinPercent
        self.fatPercent = fatPercent
        self.carbohydratePercent = carbohydratePercent
    }

    // MARK: - Transformers

    /// Convert to UI model
    func toFoodIngredient() -> FoodIngredient {
        FoodIngredient(
            name: name,
            icon: icon,
            weight: weight,
            proteinPercent: proteinPercent,
            fatPercent: fatPercent,
            carbohydratePercent: carbohydratePercent
        )
    }
}

// MARK: - MealEntity Extensions

extension MealEntity {
    /// Create from UI analysis results
    static func fromAnalysisResults(
        timestamp: Date,
        mealType: MealType,
        photo: UIImage?,
        dishes: [Dish],
        dietaryAdvice: DietaryAdviceResult?
    ) -> MealEntity {
        let dishEntities = dishes.map { dish in
            let ingredientEntities = dish.ingredients.map { ingredient in
                IngredientEntity(
                    name: ingredient.name,
                    icon: ingredient.icon,
                    weight: ingredient.weight,
                    proteinPercent: ingredient.proteinPercent,
                    fatPercent: ingredient.fatPercent,
                    carbohydratePercent: ingredient.carbohydratePercent
                )
            }
            return DishEntity(
                name: dish.name,
                icon: dish.icon,
                ingredients: ingredientEntities
            )
        }

        return MealEntity(
            timestamp: timestamp,
            mealType: mealType,
            photo: photo,
            dishes: dishEntities,
            dietaryAdvice: dietaryAdvice
        )
    }
}
