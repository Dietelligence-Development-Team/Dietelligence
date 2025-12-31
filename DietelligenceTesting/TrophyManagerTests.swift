//
//  TrophyManagerTests.swift
//  DietelligenceTesting
//
//  Tests for TrophyManager trophy detection and persistence
//

import XCTest
import SwiftData
@testable import Dietelligence

final class TrophyManagerTests: XCTestCase {

    var trophyContainer: ModelContainer!
    var mealContainer: ModelContainer!
    var userProfileContainer: ModelContainer!
    var userProfileManager: UserProfileManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create in-memory containers for testing
        trophyContainer = createTrophyContainer()
        mealContainer = SwiftDataTestHelpers.createMealContainer()
        userProfileContainer = SwiftDataTestHelpers.createUserProfileContainer()

        // Create user profile manager with test container
        userProfileManager = UserProfileManager(
            container: userProfileContainer,
            defaults: UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        )

        // Create and save test profile with nutrition targets
        let testProfile = TestHelpers.createMockUserProfile()
        userProfileManager.saveProfile(testProfile)

        // Save test nutrition targets
        let testTargets = createTestNutritionTargets()
        userProfileManager.saveNutritionTargets(testTargets)
    }

    override func tearDown() {
        trophyContainer = nil
        mealContainer = nil
        userProfileContainer = nil
        userProfileManager = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Create in-memory trophy container
    private func createTrophyContainer() -> ModelContainer {
        let schema = Schema([TrophyEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }

    /// Create test nutrition targets
    private func createTestNutritionTargets() -> NutritionTargets {
        return NutritionTargets(
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
            explanation: "Test targets",
            generatedDate: Date()
        )
    }

    /// Create a test meal with nutrition values
    private func createTestMeal(
        calories: Double,
        protein: Double,
        fat: Double,
        carb: Double,
        daysAgo: Int = 0
    ) -> MealEntity {
        let calendar = Calendar.current
        let timestamp = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!

        let ingredient = IngredientEntity(
            name: "Test Ingredient",
            icon: "🥗",
            weight: 100,
            proteinPercent: protein,
            fatPercent: fat,
            carbohydratePercent: carb
        )

        let dish = DishEntity(
            name: "Test Dish",
            icon: "🍽️",
            ingredients: [ingredient]
        )

        // Calculate total calories from macros
        let totalCalories = calories

        return MealEntity(
            timestamp: timestamp,
            mealType: .lunch,
            photo: nil,
            dishes: [dish],
            dietaryAdvice: nil
        )
    }

    /// Save meals that meet targets for consecutive days
    private func saveMealsForConsecutiveDays(count: Int) {
        let context = ModelContext(mealContainer)

        for daysAgo in 0..<count {
            // Create 3 meals per day that together meet the daily targets
            let mealsPerDay = [
                createMealWithNutrition(
                    calories: 600, protein: 40, fat: 20, carb: 70, daysAgo: daysAgo
                ),
                createMealWithNutrition(
                    calories: 700, protein: 50, fat: 25, carb: 80, daysAgo: daysAgo
                ),
                createMealWithNutrition(
                    calories: 700, protein: 50, fat: 20, carb: 90, daysAgo: daysAgo
                )
            ]

            for meal in mealsPerDay {
                context.insert(meal)
            }
        }

        try? context.save()
    }

    /// Create meal with specific nutrition values
    private func createMealWithNutrition(
        calories: Double,
        protein: Double,
        fat: Double,
        carb: Double,
        daysAgo: Int
    ) -> MealEntity {
        let calendar = Calendar.current
        let now = Date()
        let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let timestamp = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: targetDate
        )!

        // Calculate percentages based on 100g weight
        let weight = 100.0
        let proteinPercent = protein / weight * 100
        let fatPercent = fat / weight * 100
        let carbPercent = carb / weight * 100

        let ingredient = IngredientEntity(
            name: "Test Food",
            icon: "🍽️",
            weight: weight,
            proteinPercent: proteinPercent,
            fatPercent: fatPercent,
            carbohydratePercent: carbPercent
        )

        let dish = DishEntity(
            name: "Test Dish",
            icon: "🍽️",
            ingredients: [ingredient]
        )

        return MealEntity(
            timestamp: timestamp,
            mealType: .lunch,
            photo: nil,
            dishes: [dish],
            dietaryAdvice: nil
        )
    }

    // MARK: - Trophy Detection Tests

    func testCheckForNewTrophies_NoMeals_ReturnsEmptyArray() {
        // ARRANGE
        // No meals created

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        XCTAssertTrue(trophies.isEmpty, "Should return no trophies when no meals exist")
    }

    func testCheckForNewTrophies_OneDayInRange_ReturnsSingleDayTrophy() {
        // ARRANGE
        saveMealsForConsecutiveDays(count: 1)

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        XCTAssertEqual(trophies.count, 1, "Should return exactly one trophy")
        XCTAssertEqual(trophies.first?.type, .singleDay, "Trophy type should be single day")
        XCTAssertEqual(trophies.first?.streakDays, 1, "Streak should be 1 day")
    }

    func testCheckForNewTrophies_ThreeDaysInRange_ReturnsThreeDayTrophy() {
        // ARRANGE
        saveMealsForConsecutiveDays(count: 3)

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        let threeDayTrophies = trophies.filter { $0.type == .threeDay }
        XCTAssertEqual(threeDayTrophies.count, 1, "Should return one 3-day trophy")
        XCTAssertEqual(threeDayTrophies.first?.streakDays, 3, "Streak should be 3 days")
    }

    func testCheckForNewTrophies_SevenDaysInRange_ReturnsSevenDayTrophy() {
        // ARRANGE
        saveMealsForConsecutiveDays(count: 7)

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        let sevenDayTrophies = trophies.filter { $0.type == .sevenDay }
        XCTAssertEqual(sevenDayTrophies.count, 1, "Should return one 7-day trophy")
        XCTAssertEqual(sevenDayTrophies.first?.streakDays, 7, "Streak should be 7 days")
    }

    func testCheckForNewTrophies_SevenDaysInRange_ReturnsAllThreeTrophyTypes() {
        // ARRANGE
        saveMealsForConsecutiveDays(count: 7)

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        let singleDay = trophies.filter { $0.type == .singleDay }
        let threeDay = trophies.filter { $0.type == .threeDay }
        let sevenDay = trophies.filter { $0.type == .sevenDay }

        XCTAssertEqual(singleDay.count, 1, "Should have one single-day trophy")
        XCTAssertEqual(threeDay.count, 1, "Should have one 3-day trophy")
        XCTAssertEqual(sevenDay.count, 1, "Should have one 7-day trophy")
    }

    // MARK: - Duplicate Prevention Tests

    func testCheckForNewTrophies_DuplicateSingleDay_DoesNotReturnDuplicate() {
        // ARRANGE
        saveMealsForConsecutiveDays(count: 1)

        // ACT
        let firstCheck = checkForTrophiesWithTestData()
        saveTrophies(firstCheck) // Save trophies

        let secondCheck = checkForTrophiesWithTestData()

        // ASSERT
        XCTAssertEqual(firstCheck.count, 1, "First check should return trophy")
        XCTAssertTrue(secondCheck.isEmpty, "Second check should not return duplicate")
    }

    func testCheckForNewTrophies_DuplicateThreeDay_DoesNotReturnDuplicate() {
        // ARRANGE
        saveMealsForConsecutiveDays(count: 3)

        // ACT
        let firstCheck = checkForTrophiesWithTestData()
        saveTrophies(firstCheck)

        let secondCheck = checkForTrophiesWithTestData()

        // ASSERT
        let firstThreeDay = firstCheck.filter { $0.type == .threeDay }
        let secondThreeDay = secondCheck.filter { $0.type == .threeDay }

        XCTAssertEqual(firstThreeDay.count, 1, "First check should return 3-day trophy")
        XCTAssertEqual(secondThreeDay.count, 0, "Second check should not return duplicate")
    }

    // MARK: - Streak Break Tests

    func testCheckForNewTrophies_MissedDay_BreaksStreak() {
        // ARRANGE
        let context = ModelContext(mealContainer)

        // Day 0 (today): meals
        let todayMeals = [
            createMealWithNutrition(calories: 600, protein: 40, fat: 20, carb: 70, daysAgo: 0),
            createMealWithNutrition(calories: 700, protein: 50, fat: 25, carb: 80, daysAgo: 0),
            createMealWithNutrition(calories: 700, protein: 50, fat: 20, carb: 90, daysAgo: 0)
        ]
        todayMeals.forEach { context.insert($0) }

        // Day 1 (yesterday): NO MEALS (breaks streak)

        // Days 2-6: meals
        for daysAgo in 2...6 {
            let meals = [
                createMealWithNutrition(calories: 600, protein: 40, fat: 20, carb: 70, daysAgo: daysAgo),
                createMealWithNutrition(calories: 700, protein: 50, fat: 25, carb: 80, daysAgo: daysAgo),
                createMealWithNutrition(calories: 700, protein: 50, fat: 20, carb: 90, daysAgo: daysAgo)
            ]
            meals.forEach { context.insert($0) }
        }

        try? context.save()

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        let threeDayTrophies = trophies.filter { $0.type == .threeDay }
        let sevenDayTrophies = trophies.filter { $0.type == .sevenDay }

        XCTAssertEqual(threeDayTrophies.count, 0, "Should not return 3-day trophy due to break")
        XCTAssertEqual(sevenDayTrophies.count, 0, "Should not return 7-day trophy due to break")
    }

    // MARK: - Edge Cases

    func testCheckForNewTrophies_NutritionSlightlyOutOfRange_DoesNotReturnTrophy() {
        // ARRANGE
        let context = ModelContext(mealContainer)

        // Meals with calories slightly above range (2300 > 2200 max)
        let meals = [
            createMealWithNutrition(calories: 800, protein: 50, fat: 30, carb: 80, daysAgo: 0),
            createMealWithNutrition(calories: 800, protein: 50, fat: 30, carb: 80, daysAgo: 0),
            createMealWithNutrition(calories: 700, protein: 40, fat: 20, carb: 80, daysAgo: 0)
        ]
        meals.forEach { context.insert($0) }
        try? context.save()

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        XCTAssertTrue(trophies.isEmpty, "Should not return trophy when nutrients out of range")
    }

    func testCheckForNewTrophies_NoNutritionTargets_ReturnsEmptyArray() {
        // ARRANGE
        // Clear nutrition targets
        userProfileManager.clearProfile()

        saveMealsForConsecutiveDays(count: 7)

        // ACT
        let trophies = checkForTrophiesWithTestData()

        // ASSERT
        XCTAssertTrue(trophies.isEmpty, "Should return empty array when no nutrition targets")
    }

    // MARK: - Trophy Persistence Tests

    func testSaveTrophy_ValidTrophy_SavesSuccessfully() {
        // ARRANGE
        let trophy = Trophy(
            id: UUID(),
            type: .singleDay,
            earnedDate: Date(),
            streakDays: 1,
            calories: 2000,
            protein: 140,
            fat: 65,
            carbohydrate: 240
        )

        // ACT
        saveTrophyToContainer(trophy)

        // ASSERT
        let context = ModelContext(trophyContainer)
        let descriptor = FetchDescriptor<TrophyEntity>()
        let entities = (try? context.fetch(descriptor)) ?? []

        XCTAssertEqual(entities.count, 1, "Should save one trophy entity")
        XCTAssertEqual(entities.first?.type, TrophyType.singleDay.rawValue)
    }

    func testFetchAllTrophies_MultipleTrophies_ReturnsSortedByDate() {
        // ARRANGE
        let trophy1 = Trophy(
            id: UUID(),
            type: .singleDay,
            earnedDate: Date().addingTimeInterval(-86400), // Yesterday
            streakDays: 1,
            calories: 2000,
            protein: 140,
            fat: 65,
            carbohydrate: 240
        )

        let trophy2 = Trophy(
            id: UUID(),
            type: .threeDay,
            earnedDate: Date(), // Today
            streakDays: 3,
            calories: 2000,
            protein: 140,
            fat: 65,
            carbohydrate: 240
        )

        saveTrophyToContainer(trophy1)
        saveTrophyToContainer(trophy2)

        // ACT
        let trophies = fetchAllTrophiesFromContainer()

        // ASSERT
        XCTAssertEqual(trophies.count, 2, "Should fetch both trophies")
        XCTAssertEqual(trophies.first?.type, .threeDay, "Most recent trophy should be first")
    }

    // MARK: - Test Helper Methods

    /// Check for trophies using test data (mocks MealPersistenceManager)
    private func checkForTrophiesWithTestData() -> [Trophy] {
        guard let targets = userProfileManager.getNutritionTargets() else {
            return []
        }

        var newTrophies: [Trophy] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate daily totals from test meal container
        let dailyTotals = calculateDailyTotalsFromTestData(goingBack: 7, from: today)

        // Check single day achievement
        if let todayStats = dailyTotals.first {
            if targets.isAllNutrientsInRange(
                calories: todayStats.calories,
                protein: todayStats.protein,
                fat: todayStats.fat,
                carb: todayStats.carbohydrate
            ) {
                if !hasTrophyInContainer(type: .singleDay, forDate: today) {
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
                if !hasTrophyInContainer(type: .threeDay, forDate: streakStartDate) {
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
                if !hasTrophyInContainer(type: .sevenDay, forDate: streakStartDate) {
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

        return newTrophies
    }

    private struct DayStats {
        let date: Date
        let calories: Double
        let protein: Double
        let fat: Double
        let carbohydrate: Double
    }

    private func calculateDailyTotalsFromTestData(goingBack days: Int, from endDate: Date) -> [DayStats] {
        let context = ModelContext(mealContainer)
        let calendar = Calendar.current
        var results: [DayStats] = []

        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: endDate),
                  let dayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: targetDate),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }

            // Fetch meals for this day
            let predicate = #Predicate<MealEntity> { meal in
                meal.timestamp >= dayStart && meal.timestamp < dayEnd
            }
            let descriptor = FetchDescriptor<MealEntity>(predicate: predicate)
            let meals = (try? context.fetch(descriptor)) ?? []

            if meals.isEmpty {
                break // Stop if we hit a day with no meals
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

    private func hasTrophyInContainer(type: TrophyType, forDate date: Date) -> Bool {
        let context = ModelContext(trophyContainer)
        let calendar = Calendar.current

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

    private func saveTrophyToContainer(_ trophy: Trophy) {
        let context = ModelContext(trophyContainer)
        let entity = TrophyEntity(trophy: trophy)
        context.insert(entity)
        try? context.save()
    }

    private func saveTrophies(_ trophies: [Trophy]) {
        for trophy in trophies {
            saveTrophyToContainer(trophy)
        }
    }

    private func fetchAllTrophiesFromContainer() -> [Trophy] {
        let context = ModelContext(trophyContainer)
        let descriptor = FetchDescriptor<TrophyEntity>(
            sortBy: [SortDescriptor(\.earnedDate, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.map { $0.toTrophy() }
    }
}
