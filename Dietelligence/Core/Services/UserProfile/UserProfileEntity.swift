//
//  UserProfileEntity.swift
//  Dietelligence
//
//  SwiftData model for persisting user nutrition profile
//

import Foundation
import SwiftData

@Model
final class UserProfileEntity {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var name: String
    var weight: Double
    var height: Double
    var age: Int
    var gender: String
    var activityLevel: String
    var goals: [String]
    var preference: String
    var other: String

    // Nutrition targets from Gemini Planner
    var nutritionTargetsData: Data?  // JSON-encoded NutritionTargets
    var targetsGeneratedDate: Date?

    init(profile: UserNutritionProfile) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = profile.name
        self.weight = profile.weight
        self.height = profile.height
        self.age = profile.age
        self.gender = profile.gender
        self.activityLevel = profile.activityLevel
        self.goals = profile.goals
        self.preference = profile.preference
        self.other = profile.other
        self.nutritionTargetsData = nil
        self.targetsGeneratedDate = nil
    }

    func toProfile() -> UserNutritionProfile {
        UserNutritionProfile(
            name: name,
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            goals: goals,
            preference: preference,
            other: other
        )
    }

    func update(from profile: UserNutritionProfile) {
        name = profile.name
        weight = profile.weight
        height = profile.height
        age = profile.age
        gender = profile.gender
        activityLevel = profile.activityLevel
        goals = profile.goals
        preference = profile.preference
        other = profile.other
        // Note: Targets are NOT updated when profile changes
        // They must be explicitly regenerated via saveNutritionTargets()
    }

    // MARK: - Nutrition Targets

    /// Computed property to decode nutrition targets from stored Data
    var nutritionTargets: NutritionTargets? {
        guard let data = nutritionTargetsData else { return nil }
        return try? JSONDecoder().decode(NutritionTargets.self, from: data)
    }

    /// Save nutrition targets to entity
    func saveNutritionTargets(_ targets: NutritionTargets) {
        if let encoded = try? JSONEncoder().encode(targets) {
            self.nutritionTargetsData = encoded
            self.targetsGeneratedDate = Date()
        }
    }

    /// Check if nutrition targets are valid (exist and not expired)
    /// Targets are considered valid for 30 days
    func hasValidTargets() -> Bool {
        guard let _ = nutritionTargets,
              let generatedDate = targetsGeneratedDate else {
            return false
        }

        // Targets are valid for 30 days
        let daysSinceGeneration = Calendar.current.dateComponents(
            [.day],
            from: generatedDate,
            to: Date()
        ).day ?? 999

        return daysSinceGeneration < 30
    }
}
