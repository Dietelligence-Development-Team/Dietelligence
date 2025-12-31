//
//  MealPersistenceManager.swift
//  Dietelligence
//
//  Singleton manager for meal persistence using SwiftData
//

import Foundation
import SwiftData
import UIKit

class MealPersistenceManager {
    static let shared = MealPersistenceManager()

    private let container: ModelContainer

    // MARK: - Initialization

    private init() {
        let schema = Schema([
            MealEntity.self,
            DishEntity.self,
            IngredientEntity.self
        ])

        // Use separate database file - Apple official best practice
        // This prevents schema conflicts with UserProfileManager's default.store
        let storeURL = URL.documentsDirectory.appending(path: "MealHistory.sqlite")
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL
        )

        do {
            container = try ModelContainer(for: schema, configurations: configuration)
            print("✓ MealPersistenceManager initialized at: \(storeURL.path)")
        } catch {
            fatalError("Failed to create ModelContainer for meal persistence: \(error)")
        }
    }

    // MARK: - Save Meal

    /// Save a meal to persistent storage
    /// - Parameters:
    ///   - timestamp: When the meal photo was taken (defaults to now)
    ///   - mealType: Type of meal (Breakfast/Lunch/Dinner/Snack)
    ///   - photo: Captured photo of the meal (will be compressed)
    ///   - dishes: Array of dishes analyzed from the photo
    ///   - dietaryAdvice: Nutritional advice from Gemini (optional)
    /// - Throws: Error if save fails
    func saveMeal(
        timestamp: Date = Date(),
        mealType: MealType,
        photo: UIImage?,
        dishes: [Dish],
        dietaryAdvice: DietaryAdviceResult?
    ) throws {
        let context = ModelContext(container)

        let meal = MealEntity.fromAnalysisResults(
            timestamp: timestamp,
            mealType: mealType,
            photo: photo,
            dishes: dishes,
            dietaryAdvice: dietaryAdvice
        )

        context.insert(meal)
        try context.save()

        print("✓ Saved meal: \(mealType.rawValue) at \(timestamp)")
    }

    // MARK: - Fetch Meals

    /// Fetch all meals sorted by timestamp (newest first)
    /// - Returns: Array of MealEntity objects
    func fetchAllMeals() -> [MealEntity] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<MealEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch meals within a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of MealEntity objects
    func fetchMeals(from startDate: Date, to endDate: Date) -> [MealEntity] {
        let context = ModelContext(container)
        let predicate = #Predicate<MealEntity> { meal in
            meal.timestamp >= startDate && meal.timestamp <= endDate
        }

        let descriptor = FetchDescriptor<MealEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch recent meals with a limit
    /// - Parameter limit: Maximum number of meals to fetch (default: 20)
    /// - Returns: Array of MealEntity objects
    func fetchRecentMeals(limit: Int = 20) -> [MealEntity] {
        let meals = fetchAllMeals()
        return Array(meals.prefix(limit))
    }

    // MARK: - Delete Meal

    /// Delete a meal from persistent storage
    /// - Parameter meal: The meal to delete
    /// - Throws: Error if delete fails
    func deleteMeal(_ meal: MealEntity) throws {
        let context = ModelContext(container)
        context.delete(meal)
        try context.save()
        print("✓ Deleted meal: \(meal.mealTypeEnum.rawValue) at \(meal.timestamp)")
    }

    // MARK: - Statistics

    /// Get total count of saved meals
    /// - Returns: Number of meals in storage
    func getMealCount() -> Int {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<MealEntity>()
        return (try? context.fetch(descriptor).count) ?? 0
    }

    // MARK: - Helper Methods

    /// Determine meal type based on current time
    /// - Returns: MealType based on hour of day
    static func determineMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<10:
            return .breakfast
        case 10..<15:
            return .lunch
        case 15..<22:
            return .dinner
        default:
            return .snack
        }
    }
}
