//
//  GeminiConfiguration.swift
//  Dietelligence
//
//  Centralized Gemini API configuration
//

import Foundation

struct GeminiConfiguration {

    // MARK: - Constants

    private static let keychainAccount = "gemini_api_key"

    // MARK: - Public Properties

    /// Retrieves the Gemini API key from secure storage
    /// Priority: 1. Keychain (production), 2. UserDefaults (testing only)
    /// - Returns: API key if found, nil otherwise
    static var apiKey: String? {
        // Priority 1: Read from Keychain (secure)
        if let key = try? KeychainManager.retrieve(keychainAccount), !key.isEmpty {
            return key
        }

        // Priority 2: UserDefaults fallback (for testing/development only)
        // This allows GeminiTestView to work with temporary keys
        if let key = UserDefaults.standard.string(forKey: keychainAccount), !key.isEmpty {
            print("⚠️ WARNING: Using API key from UserDefaults (testing mode)")
            return key
        }

        return nil
    }

    /// Check if API key is configured
    static var hasAPIKey: Bool {
        return apiKey != nil
    }

    // MARK: - Public Methods

    /// Save API key to secure Keychain storage
    /// - Parameter key: The API key to save
    /// - Throws: KeychainError if save fails
    static func saveAPIKey(_ key: String) throws {
        try KeychainManager.save(key, forAccount: keychainAccount)
        print("✓ API key saved to Keychain")
    }

    /// Delete API key from secure storage
    /// - Throws: KeychainError if deletion fails
    static func deleteAPIKey() throws {
        try KeychainManager.delete(keychainAccount)
        UserDefaults.standard.removeObject(forKey: keychainAccount)
        print("✓ API key deleted")
    }

    // MARK: - Testing Support

    /// Save API key to UserDefaults (for testing purposes only)
    /// This is used by GeminiTestView for temporary testing
    static func saveTestAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: keychainAccount)
        print("⚠️ Test API key saved to UserDefaults (not secure)")
    }

    // MARK: - Migration Support

    /// Migrate API key from Info.plist to Keychain (one-time operation)
    /// This ensures existing users don't lose their configured API key
    static func migrateFromInfoPlistIfNeeded() {
        // Check if already migrated
        if hasAPIKey {
            return // Already in Keychain
        }

        // Check if Info.plist has a key
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !infoPlistKey.isEmpty {

            do {
                try saveAPIKey(infoPlistKey)
                print("✓ Migrated API key from Info.plist to Keychain")
            } catch {
                print("⚠️ Failed to migrate API key: \(error.localizedDescription)")
            }
        }
    }
}
