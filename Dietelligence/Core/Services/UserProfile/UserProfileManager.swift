//
//  UserProfileManager.swift
//  Dietelligence
//
//  Manages user nutrition profile and preferences
//

import Foundation
import SwiftData

class UserProfileManager {
    static let shared = UserProfileManager()

    private let container: ModelContainer
    private let defaults: UserDefaults
    private let onboardingKey = "dietelligence_onboarding_needed"

    init(container: ModelContainer, defaults: UserDefaults = .standard) {
        self.container = container
        self.defaults = defaults
    }

    private init() {
        // Initialize defaults first
        defaults = .standard

        // Create a dedicated SwiftData container for profile persistence.
        // Health check: If database is corrupted, recreate it
        do {
            let schema = Schema([UserProfileEntity.self])
            container = try ModelContainer(for: schema)
        } catch {
            print("⚠️ UserProfile database corrupted, recreating...")

            // Delete corrupted database files
            let defaultStoreURL = URL.documentsDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: defaultStoreURL)
            try? FileManager.default.removeItem(at: defaultStoreURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: defaultStoreURL.appendingPathExtension("wal"))

            // Recreate container
            let schema = Schema([UserProfileEntity.self])
            container = try! ModelContainer(for: schema)

            // Force onboarding for new database
            defaults.set(true, forKey: onboardingKey)
            print("✓ UserProfile database recreated, onboarding required")
        }
    }

    /// Get user's nutrition profile
    /// Returns cached profile or default profile if not set
    func getProfile() -> UserNutritionProfile {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])

        if let entity = try? context.fetch(descriptor).first {
            return entity.toProfile()
        }

        // If nothing saved, return default without persisting
        return createDefaultProfile()
    }

    /// Save user's nutrition profile
    func saveProfile(_ profile: UserNutritionProfile) {
        let context = ModelContext(container)

        // Try to fetch existing
        let descriptor = FetchDescriptor<UserProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: profile)
            try? context.save()
        } else {
            // Otherwise insert new
            let entity = UserProfileEntity(profile: profile)
            context.insert(entity)
            try? context.save()
        }

        defaults.set(false, forKey: onboardingKey)
    }

    /// Check if user has configured their profile
    func hasProfile() -> Bool {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileEntity>()
        let count = (try? context.fetch(descriptor).count) ?? 0
        return count > 0
    }

    /// Clear user profile (for logout or reset)
    func clearProfile() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileEntity>()
        if let results = try? context.fetch(descriptor) {
            results.forEach { context.delete($0) }
            try? context.save()
        }
        defaults.set(true, forKey: onboardingKey)
    }

    /// Whether onboarding should be forced (e.g., after reset)
    func needsOnboarding() -> Bool {
        defaults.bool(forKey: onboardingKey)
    }

    func setOnboardingNeeded(_ needed: Bool) {
        defaults.set(needed, forKey: onboardingKey)
    }

    // MARK: - Nutrition Targets Management

    /// Get nutrition targets for current user
    /// Returns nil if no targets or targets expired (30+ days old)
    func getNutritionTargets() -> NutritionTargets? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])

        guard let entity = try? context.fetch(descriptor).first,
              entity.hasValidTargets() else {
            return nil
        }

        return entity.nutritionTargets
    }

    /// Save nutrition targets for current user
    func saveNutritionTargets(_ targets: NutritionTargets) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])

        if let entity = try? context.fetch(descriptor).first {
            entity.saveNutritionTargets(targets)
            try? context.save()
            print("✓ Nutrition targets saved")
        } else {
            print("⚠️ No user profile found, cannot save targets")
        }
    }

    /// Check if user has valid nutrition targets (not expired)
    func hasValidTargets() -> Bool {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])

        guard let entity = try? context.fetch(descriptor).first else {
            return false
        }

        return entity.hasValidTargets()
    }

    /// Generate nutrition targets using Gemini API
    func generateNutritionTargets(apiKey: String) async throws {
        let profile = getProfile()
        let planner = GeminiNutritionPlanner(apiKey: apiKey)
        let result = try await planner.generateNutritionTargets(profile: profile)
        let targets = NutritionTargets(from: result)
        saveNutritionTargets(targets)
    }

    // MARK: - Private Helpers

    func defaultProfile() -> UserNutritionProfile {
        return UserNutritionProfile(
            name: "",
            weight: 70,
            height: 170,
            age: 25,
            gender: "Male",
            activityLevel: "Moderate",
            goals: [],
            preference: "",
            other: ""
        )
    }

    private func createDefaultProfile() -> UserNutritionProfile {
        defaultProfile()
    }
}
