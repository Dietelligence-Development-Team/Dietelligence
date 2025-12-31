//
//  DietelligenceApp.swift
//  Dietelligence
//
//  Created by Cosmos on 14/10/2025.
//

import SwiftUI
import Combine

@main
struct DietelligenceApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("dietelligence_onboarding_needed") private var onboardingNeeded = false

    init() {
        // Perform one-time migrations on app launch
        GeminiConfiguration.migrateFromInfoPlistIfNeeded()
        Self.cleanupLegacyNutritionHistory()
        Self.ensureNutritionTargets()
        Self.checkTrophiesOnStartup()
    }

    /// Clean up legacy UserDefaults-based nutrition history (one-time migration)
    private static func cleanupLegacyNutritionHistory() {
        if UserDefaults.standard.object(forKey: "nutrition_history") != nil {
            UserDefaults.standard.removeObject(forKey: "nutrition_history")
            UserDefaults.standard.removeObject(forKey: "three_day_nutrition_average")
            print("✓ Cleaned up legacy UserDefaults nutrition history")
        }
    }

    /// Generate nutrition targets if profile exists but no valid targets
    private static func ensureNutritionTargets() {
        Task { @MainActor in
            // Only run if profile exists but no valid targets
            guard UserProfileManager.shared.hasProfile(),
                  !UserProfileManager.shared.hasValidTargets(),
                  let apiKey = GeminiConfiguration.apiKey else {
                return
            }

            do {
                print("🔄 Generating missing nutrition targets on startup...")
                try await UserProfileManager.shared.generateNutritionTargets(apiKey: apiKey)
                print("✓ Nutrition targets generated on startup")
            } catch {
                print("⚠️ Failed to generate nutrition targets on startup: \(error.localizedDescription)")
            }
        }
    }

    /// Check for new trophies on app startup
    private static func checkTrophiesOnStartup() {
        // Run in background to not block startup
        Task.detached {
            let newTrophies = TrophyManager.shared.checkForNewTrophies()
            if !newTrophies.isEmpty {
                print("🏆 \(newTrophies.count) trophy(ies) earned on startup!")
                // Note: Trophies earned on startup won't show popup
                // User can check trophy history to see them
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingNeeded || !UserProfileManager.shared.hasProfile() {
                    OnboardingFlowView {
                        onboardingNeeded = false
                    }
                } else {
                    // Main app
                    Group {
                        if appState.hasAPIKey {
                            // Create ViewModel only when API key is available
                            CameraView()
                                .environmentObject(appState)
                                .environmentObject(appState.getOrCreateViewModel())
                        } else {
                            // Show placeholder while API key is being configured
                            Color.backGround
                                .ignoresSafeArea()
                                .environmentObject(appState)
                        }
                    }
                    .fullScreenCover(isPresented: Binding(
                        get: { !appState.hasAPIKey },
                        set: { _ in }
                    )) {
                        // Show API key setup if not configured
                        APISettingView()
                            .environmentObject(appState)
                    }
                }
            }
            .preferredColorScheme(.light) // Force light mode, ignore system dark mode
        }
    }
}

// MARK: - App State Manager

/// Manages lazy initialization of ViewModels
@MainActor
class AppState: ObservableObject {
    @Published private var analysisViewModel: FoodAnalysisViewModel?
    @Published var hasAPIKey: Bool

    init() {
        self.hasAPIKey = GeminiConfiguration.hasAPIKey
    }

    func getOrCreateViewModel() -> FoodAnalysisViewModel {
        if let existing = analysisViewModel {
            return existing
        }

        // Create new ViewModel only when API key is available
        guard let apiKey = GeminiConfiguration.apiKey else {
            fatalError("API key should be available at this point")
        }

        let viewModel = FoodAnalysisViewModel(apiKey: apiKey)
        analysisViewModel = viewModel
        return viewModel
    }

    func resetViewModel() {
        analysisViewModel = nil
    }

    func refreshAPIKeyStatus() {
        hasAPIKey = GeminiConfiguration.hasAPIKey
    }
}

