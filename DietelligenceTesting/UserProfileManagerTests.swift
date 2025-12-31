//
//  UserProfileManagerTests.swift
//  DietelligenceTesting
//
//  Tests for UserProfileManager with SwiftData persistence
//

import XCTest
import SwiftData
@testable import Dietelligence

final class UserProfileManagerTests: XCTestCase {

    var testContainer: ModelContainer!
    var testDefaults: UserDefaults!
    var manager: UserProfileManager!
    var testProfile: Dietelligence.UserNutritionProfile!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create in-memory SwiftData container
        testContainer = SwiftDataTestHelpers.createUserProfileContainer()

        // Create test-specific UserDefaults
        let suiteName = "test_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!

        // Create manager with test dependencies
        manager = UserProfileManager(container: testContainer, defaults: testDefaults)

        // Create test profile
        testProfile = Dietelligence.UserNutritionProfile(
            name: "Test User",
            weight: 75,
            height: 180,
            age: 30,
            gender: "Male",
            activityLevel: "Moderate",
            goals: ["Maintain weight", "Build muscle"],
            preference: "No dairy",
            other: "None"
        )
    }

    override func tearDown() {
        testContainer = nil
        if let suiteName = testDefaults.dictionaryRepresentation().keys.first {
            testDefaults.removePersistentDomain(forName: suiteName)
        }
        testDefaults = nil
        manager = nil
        testProfile = nil
        super.tearDown()
    }

    // MARK: - Save Profile Tests

    /// Test saving a new profile creates entity
    func testSaveProfile_NewProfile_CreatesEntity() {
        // ACT
        manager.saveProfile(testProfile)

        // ASSERT
        let retrieved = manager.getProfile()
        XCTAssertEqual(retrieved.name, "Test User", "Name should match")
        XCTAssertEqual(retrieved.weight, 75, "Weight should match")
        XCTAssertEqual(retrieved.height, 180, "Height should match")
        XCTAssertEqual(retrieved.age, 30, "Age should match")
    }

    /// Test saving over existing profile updates it
    func testSaveProfile_ExistingProfile_UpdatesEntity() {
        // ARRANGE
        manager.saveProfile(testProfile)

        // Update profile
        let updatedProfile = Dietelligence.UserNutritionProfile(
            name: "Updated User",
            weight: 80,
            height: 185,
            age: 31,
            gender: "Female",
            activityLevel: "Active",
            goals: ["Lose weight"],
            preference: "Vegan",
            other: "Updated"
        )

        // ACT
        manager.saveProfile(updatedProfile)

        // ASSERT
        let retrieved = manager.getProfile()
        XCTAssertEqual(retrieved.name, "Updated User", "Name should be updated")
        XCTAssertEqual(retrieved.weight, 80, "Weight should be updated")
        XCTAssertEqual(retrieved.gender, "Female", "Gender should be updated")
    }

    // MARK: - Get Profile Tests

    /// Test getting existing profile returns correct data
    func testGetProfile_ExistingProfile_ReturnsCorrectData() {
        // ARRANGE
        manager.saveProfile(testProfile)

        // ACT
        let retrieved = manager.getProfile()

        // ASSERT
        XCTAssertEqual(retrieved.name, testProfile.name, "All fields should match")
        XCTAssertEqual(retrieved.weight, testProfile.weight)
        XCTAssertEqual(retrieved.height, testProfile.height)
        XCTAssertEqual(retrieved.age, testProfile.age)
        XCTAssertEqual(retrieved.gender, testProfile.gender)
        XCTAssertEqual(retrieved.activityLevel, testProfile.activityLevel)
        XCTAssertEqual(retrieved.goals, testProfile.goals)
        XCTAssertEqual(retrieved.preference, testProfile.preference)
        XCTAssertEqual(retrieved.other, testProfile.other)
    }

    /// Test getting profile when none exists returns default
    func testGetProfile_NoProfile_ReturnsDefaultProfile() {
        // ACT
        let retrieved = manager.getProfile()

        // ASSERT
        XCTAssertEqual(retrieved.name, "", "Default name should be empty")
        XCTAssertEqual(retrieved.weight, 70, "Default weight should be 70")
        XCTAssertEqual(retrieved.height, 170, "Default height should be 170")
        XCTAssertEqual(retrieved.age, 25, "Default age should be 25")
        XCTAssertEqual(retrieved.gender, "Male", "Default gender should be Male")
    }

    // MARK: - Onboarding State Tests

    /// Test onboarding needed for new user
    func testNeedsOnboarding_NewUser_ReturnsTrue() {
        // ARRANGE
        manager.setOnboardingNeeded(true)

        // ACT
        let needsOnboarding = manager.needsOnboarding()

        // ASSERT
        XCTAssertTrue(needsOnboarding, "New user should need onboarding")
    }

    /// Test onboarding not needed after saving profile
    func testNeedsOnboarding_AfterSave_ReturnsFalse() {
        // ARRANGE
        manager.setOnboardingNeeded(true)
        manager.saveProfile(testProfile)

        // ACT
        let needsOnboarding = manager.needsOnboarding()

        // ASSERT
        XCTAssertFalse(needsOnboarding, "Should not need onboarding after saving profile")
    }

    /// Test onboarding needed after clear
    func testNeedsOnboarding_AfterClear_ReturnsTrue() {
        // ARRANGE
        manager.saveProfile(testProfile)
        manager.clearProfile()

        // ACT
        let needsOnboarding = manager.needsOnboarding()

        // ASSERT
        XCTAssertTrue(needsOnboarding, "Should need onboarding after clearing profile")
    }

    // MARK: - Profile Existence Tests

    /// Test hasProfile returns false when no profile
    func testHasProfile_NoProfile_ReturnsFalse() {
        // ACT
        let hasProfile = manager.hasProfile()

        // ASSERT
        XCTAssertFalse(hasProfile, "Should return false when no profile exists")
    }

    /// Test hasProfile returns true after save
    func testHasProfile_AfterSave_ReturnsTrue() {
        // ARRANGE
        manager.saveProfile(testProfile)

        // ACT
        let hasProfile = manager.hasProfile()

        // ASSERT
        XCTAssertTrue(hasProfile, "Should return true after saving profile")
    }

    /// Test hasProfile returns false after clear
    func testHasProfile_AfterClear_ReturnsFalse() {
        // ARRANGE
        manager.saveProfile(testProfile)
        manager.clearProfile()

        // ACT
        let hasProfile = manager.hasProfile()

        // ASSERT
        XCTAssertFalse(hasProfile, "Should return false after clearing profile")
    }

    // MARK: - Clear Profile Tests

    /// Test clear profile removes all data
    func testClearProfile_RemovesAllData() {
        // ARRANGE
        manager.saveProfile(testProfile)
        XCTAssertTrue(manager.hasProfile(), "Profile should exist before clear")

        // ACT
        manager.clearProfile()

        // ASSERT
        XCTAssertFalse(manager.hasProfile(), "Profile should not exist after clear")
        let retrieved = manager.getProfile()
        XCTAssertEqual(retrieved.name, "", "Should return default profile after clear")
    }

    // MARK: - Default Profile Tests

    /// Test default profile has correct values
    func testDefaultProfile_HasCorrectDefaultValues() {
        // ACT
        let defaultProfile = manager.defaultProfile()

        // ASSERT
        XCTAssertEqual(defaultProfile.name, "", "Default name should be empty")
        XCTAssertEqual(defaultProfile.weight, 70, "Default weight should be 70")
        XCTAssertEqual(defaultProfile.height, 170, "Default height should be 170")
        XCTAssertEqual(defaultProfile.age, 25, "Default age should be 25")
        XCTAssertEqual(defaultProfile.gender, "Male", "Default gender should be Male")
        XCTAssertEqual(defaultProfile.activityLevel, "Moderate", "Default activity level should be Moderate")
        XCTAssertTrue(defaultProfile.goals.isEmpty, "Default goals should be empty")
    }
}
