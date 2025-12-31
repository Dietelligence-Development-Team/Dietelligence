//
//  KeychainManagerTests.swift
//  DietelligenceTesting
//
//  Tests for secure Keychain storage operations
//

import XCTest
@testable import Dietelligence

final class KeychainManagerTests: XCTestCase {

    var testAccount: String!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Use unique account per test to avoid collisions
        testAccount = "test_\(UUID().uuidString)"
    }

    override func tearDown() {
        // Clean up test data
        try? KeychainManager.delete(testAccount)
        super.tearDown()
    }

    // MARK: - Save Tests

    /// Test saving a new value creates a Keychain item
    func testSave_NewValue_CreatesKeychainItem() throws {
        // ARRANGE
        let testValue = "test_api_key_12345"

        // ACT
        try KeychainManager.save(testValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, testValue, "Retrieved value should match saved value")
    }

    /// Test saving over an existing value updates it
    func testSave_ExistingValue_UpdatesKeychainItem() throws {
        // ARRANGE
        let originalValue = "original_key"
        let updatedValue = "updated_key"
        try KeychainManager.save(originalValue, forAccount: testAccount)

        // ACT
        try KeychainManager.save(updatedValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, updatedValue, "Should retrieve the updated value")
    }

    /// Test saving an empty string succeeds
    func testSave_EmptyString_SavesSuccessfully() throws {
        // ARRANGE
        let emptyValue = ""

        // ACT
        try KeychainManager.save(emptyValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, emptyValue, "Should handle empty strings")
    }

    // MARK: - Retrieve Tests

    /// Test retrieving an existing value returns correct string
    func testRetrieve_ExistingValue_ReturnsCorrectString() throws {
        // ARRANGE
        let testValue = "my_secure_key"
        try KeychainManager.save(testValue, forAccount: testAccount)

        // ACT
        let retrieved = try KeychainManager.retrieve(testAccount)

        // ASSERT
        XCTAssertEqual(retrieved, testValue, "Should retrieve exact value that was saved")
    }

    /// Test retrieving a non-existent value throws itemNotFound error
    func testRetrieve_NonExistentValue_ThrowsItemNotFoundError() {
        // ARRANGE
        let nonExistentAccount = "nonexistent_\(UUID().uuidString)"

        // ACT & ASSERT
        XCTAssertThrowsError(try KeychainManager.retrieve(nonExistentAccount)) { error in
            XCTAssertTrue(error is KeychainManager.KeychainError, "Should throw KeychainError")
            if case KeychainManager.KeychainError.itemNotFound = error {
                // Success - correct error type
            } else {
                XCTFail("Should throw itemNotFound error, got \(error)")
            }
        }
    }

    // MARK: - Delete Tests

    /// Test deleting an existing value removes it successfully
    func testDelete_ExistingValue_RemovesSuccessfully() throws {
        // ARRANGE
        try KeychainManager.save("test_value", forAccount: testAccount)

        // ACT
        try KeychainManager.delete(testAccount)

        // ASSERT
        XCTAssertThrowsError(try KeychainManager.retrieve(testAccount)) { error in
            if case KeychainManager.KeychainError.itemNotFound = error {
                // Success - item was deleted
            } else {
                XCTFail("Should throw itemNotFound after delete")
            }
        }
    }

    /// Test deleting a non-existent value does not throw error (idempotent)
    func testDelete_NonExistentValue_DoesNotThrowError() {
        // ARRANGE
        let nonExistentAccount = "nonexistent_\(UUID().uuidString)"

        // ACT & ASSERT
        XCTAssertNoThrow(try KeychainManager.delete(nonExistentAccount),
                        "Delete should be idempotent and not throw for non-existent items")
    }

    // MARK: - Full Lifecycle Tests

    /// Test save → delete → retrieve flow
    func testSaveDeleteRetrieve_DeletedValue_ThrowsItemNotFound() throws {
        // ARRANGE
        let testValue = "lifecycle_test"
        try KeychainManager.save(testValue, forAccount: testAccount)
        try KeychainManager.delete(testAccount)

        // ACT & ASSERT
        XCTAssertThrowsError(try KeychainManager.retrieve(testAccount)) { error in
            if case KeychainManager.KeychainError.itemNotFound = error {
                // Success
            } else {
                XCTFail("Should not find deleted item")
            }
        }
    }

    /// Test save → update → retrieve flow
    func testSaveUpdateFlow_SaveThenUpdate_RetrievesLatestValue() throws {
        // ARRANGE
        let value1 = "first_value"
        let value2 = "second_value"
        let value3 = "third_value"

        // ACT
        try KeychainManager.save(value1, forAccount: testAccount)
        try KeychainManager.save(value2, forAccount: testAccount)
        try KeychainManager.save(value3, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, value3, "Should always retrieve the latest saved value")
    }

    // MARK: - Edge Cases

    /// Test saving a very long string handles correctly
    func testSave_VeryLongString_HandlesCorrectly() throws {
        // ARRANGE
        let longValue = String(repeating: "a", count: 5000)

        // ACT
        try KeychainManager.save(longValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, longValue, "Should handle very long strings")
        XCTAssertEqual(retrieved.count, 5000, "Length should be preserved")
    }

    /// Test saving Unicode characters preserves encoding
    func testSave_UnicodeCharacters_PreservesEncoding() throws {
        // ARRANGE
        let unicodeValue = "API密钥🔑测试KEY中文😀"

        // ACT
        try KeychainManager.save(unicodeValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, unicodeValue, "Should preserve Unicode characters")
    }

    /// Test saving special characters
    func testSave_SpecialCharacters_SavesAndRetrievesCorrectly() throws {
        // ARRANGE
        let specialValue = "!@#$%^&*()_+-=[]{}|;':\",./<>?"

        // ACT
        try KeychainManager.save(specialValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, specialValue, "Should handle special characters")
    }

    /// Test saving whitespace and newlines
    func testSave_WhitespaceAndNewlines_PreservesFormat() throws {
        // ARRANGE
        let whitespaceValue = "  test  \n  with  \n  newlines  "

        // ACT
        try KeychainManager.save(whitespaceValue, forAccount: testAccount)

        // ASSERT
        let retrieved = try KeychainManager.retrieve(testAccount)
        XCTAssertEqual(retrieved, whitespaceValue, "Should preserve whitespace and newlines")
    }

    // MARK: - Multiple Account Tests

    /// Test multiple accounts can coexist
    func testMultipleAccounts_IndependentStorage() throws {
        // ARRANGE
        let account1 = "test_account_1_\(UUID().uuidString)"
        let account2 = "test_account_2_\(UUID().uuidString)"
        let value1 = "value_for_account_1"
        let value2 = "value_for_account_2"

        // ACT
        try KeychainManager.save(value1, forAccount: account1)
        try KeychainManager.save(value2, forAccount: account2)

        // ASSERT
        let retrieved1 = try KeychainManager.retrieve(account1)
        let retrieved2 = try KeychainManager.retrieve(account2)
        XCTAssertEqual(retrieved1, value1, "Account 1 should have its value")
        XCTAssertEqual(retrieved2, value2, "Account 2 should have its value")

        // Cleanup
        try KeychainManager.delete(account1)
        try KeychainManager.delete(account2)
    }
}
