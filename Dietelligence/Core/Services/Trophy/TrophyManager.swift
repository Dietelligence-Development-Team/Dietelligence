//
//  TrophyManager.swift
//  Dietelligence
//
//  Trophy detection logic and persistence management
//

import Foundation
import SwiftData

class TrophyManager {
    static let shared = TrophyManager()

    private let container: ModelContainer

    // MARK: - Initialization

    private init() {
        let schema = Schema([TrophyEntity.self])
        let storeURL = URL.documentsDirectory.appending(path: "Trophies.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            container = try ModelContainer(for: schema, configurations: configuration)
            print("✓ TrophyManager initialized at: \(storeURL.path)")
        } catch {
            fatalError("Failed to create ModelContainer for trophies: \(error)")
        }
    }

    // MARK: - Trophy Detection

    /// Check for new trophies based on current daily nutrition and history
    /// Call this after saving a meal or on app startup
    /// Returns newly earned trophies (if any)
    func checkForNewTrophies() -> [Trophy] {
        guard let targets = UserProfileManager.shared.getNutritionTargets() else {
            print("⚠️ No nutrition targets, cannot check for trophies")
            return []
        }

        var newTrophies: [Trophy] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get daily totals for consecutive days going back
        let dailyTotals = calculateDailyTotals(goingBack: 7, from: today)

        // Check single day achievement (today)
        if let todayStats = dailyTotals.first {
            if targets.isAllNutrientsInRange(
                calories: todayStats.calories,
                protein: todayStats.protein,
                fat: todayStats.fat,
                carb: todayStats.carbohydrate
            ) {
                // Check if we already have a single-day trophy for today
                if !hasTrophy(type: .singleDay, forDate: today) {
                    let trophy = Trophy(
                        id: UUID(),
                        type: .singleDay,
                        earnedDate: Date(),
                        streakDays: 1,
                        calories: todayStats.calories,
                        protein: todayStats.protein,
                        fat: todayStats.fat,
                        carbohydrate: todayStats.carbohydrate
                    )
                    newTrophies.append(trophy)
                }
            }
        }

        // Check 3-day streak
        if dailyTotals.count >= 3 {
            let last3Days = Array(dailyTotals.prefix(3))
            if allDaysInRange(last3Days, targets: targets) {
                let streakStartDate = calendar.date(byAdding: .day, value: -2, to: today)!
                if !hasTrophy(type: .threeDay, forDate: streakStartDate) {
                    let avgStats = calculateAverage(last3Days)
                    let trophy = Trophy(
                        id: UUID(),
                        type: .threeDay,
                        earnedDate: Date(),
                        streakDays: 3,
                        calories: avgStats.calories,
                        protein: avgStats.protein,
                        fat: avgStats.fat,
                        carbohydrate: avgStats.carbohydrate
                    )
                    newTrophies.append(trophy)
                }
            }
        }

        // Check 7-day streak
        if dailyTotals.count >= 7 {
            let last7Days = Array(dailyTotals.prefix(7))
            if allDaysInRange(last7Days, targets: targets) {
                let streakStartDate = calendar.date(byAdding: .day, value: -6, to: today)!
                if !hasTrophy(type: .sevenDay, forDate: streakStartDate) {
                    let avgStats = calculateAverage(last7Days)
                    let trophy = Trophy(
                        id: UUID(),
                        type: .sevenDay,
                        earnedDate: Date(),
                        streakDays: 7,
                        calories: avgStats.calories,
                        protein: avgStats.protein,
                        fat: avgStats.fat,
                        carbohydrate: avgStats.carbohydrate
                    )
                    newTrophies.append(trophy)
                }
            }
        }

        // Save new trophies
        for trophy in newTrophies {
            saveTrophy(trophy)
        }

        return newTrophies
    }

    // MARK: - Private Helpers

    private struct DayStats {
        let date: Date
        let calories: Double
        let protein: Double
        let fat: Double
        let carbohydrate: Double
    }

    /// Calculate daily nutrition totals for the last N days
    private func calculateDailyTotals(goingBack days: Int, from endDate: Date) -> [DayStats] {
        let calendar = Calendar.current
        var results: [DayStats] = []

        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: endDate),
                  let dayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: targetDate),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }

            // Fetch meals for this day
            let meals = MealPersistenceManager.shared.fetchMeals(from: dayStart, to: dayEnd)

            if meals.isEmpty {
                break  // Stop if we hit a day with no meals (breaks streak)
            }

            // Calculate totals
            let totalCalories = meals.reduce(0) { $0 + $1.totalCalories }
            let totalProtein = meals.reduce(0) { $0 + $1.totalProtein }
            let totalFat = meals.reduce(0) { $0 + $1.totalFat }
            let totalCarbs = meals.reduce(0) { $0 + $1.totalCarbohydrate }

            results.append(DayStats(
                date: dayStart,
                calories: totalCalories,
                protein: totalProtein,
                fat: totalFat,
                carbohydrate: totalCarbs
            ))
        }

        return results
    }

    private func allDaysInRange(_ days: [DayStats], targets: NutritionTargets) -> Bool {
        return days.allSatisfy { day in
            targets.isAllNutrientsInRange(
                calories: day.calories,
                protein: day.protein,
                fat: day.fat,
                carb: day.carbohydrate
            )
        }
    }

    private func calculateAverage(_ days: [DayStats]) -> DayStats {
        let count = Double(days.count)
        return DayStats(
            date: Date(),
            calories: days.reduce(0) { $0 + $1.calories } / count,
            protein: days.reduce(0) { $0 + $1.protein } / count,
            fat: days.reduce(0) { $0 + $1.fat } / count,
            carbohydrate: days.reduce(0) { $0 + $1.carbohydrate } / count
        )
    }

    /// Check if trophy already exists for a specific date range
    private func hasTrophy(type: TrophyType, forDate date: Date) -> Bool {
        let context = ModelContext(container)
        let calendar = Calendar.current

        // Define search window based on trophy type
        let daysBack: Int
        switch type {
        case .singleDay: daysBack = 1
        case .threeDay: daysBack = 3
        case .sevenDay: daysBack = 7
        }

        guard let windowStart = calendar.date(byAdding: .day, value: -daysBack, to: date) else {
            return false
        }

        let now = Date()
        let predicate = #Predicate<TrophyEntity> { trophy in
            trophy.type == type.rawValue &&
            trophy.earnedDate >= windowStart &&
            trophy.earnedDate <= now
        }

        let descriptor = FetchDescriptor<TrophyEntity>(predicate: predicate)
        let count = (try? context.fetch(descriptor).count) ?? 0

        return count > 0
    }

    // MARK: - Persistence

    private func saveTrophy(_ trophy: Trophy) {
        let context = ModelContext(container)
        let entity = TrophyEntity(trophy: trophy)
        context.insert(entity)
        try? context.save()
        print("🏆 Trophy earned: \(trophy.type.title)")
    }

    /// Public method to save trophy directly (for test data generation)
    func saveTrophyDirectly(_ trophy: Trophy) {
        saveTrophy(trophy)
    }

    func fetchAllTrophies() -> [Trophy] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TrophyEntity>(
            sortBy: [SortDescriptor(\.earnedDate, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.map { $0.toTrophy() }
    }

    func getTrophyCount() -> Int {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TrophyEntity>()
        return (try? context.fetch(descriptor).count) ?? 0
    }
}
