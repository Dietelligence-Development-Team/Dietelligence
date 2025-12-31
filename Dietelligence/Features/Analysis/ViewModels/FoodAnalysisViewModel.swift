//
//  FoodAnalysisViewModel.swift
//  Dietelligence
//
//  Main ViewModel for food analysis flow
//  Orchestrates Gemini API calls and manages UI state
//

import SwiftUI
import UIKit
import Combine

/// Analysis flow states
enum AnalysisState {
    case idle
    case uploadingImage
    case analyzingFood      // Show "Analyzing..." in AnalysisResultView
    case transformingData
    case fetchingAdvice     // Show loading in SuggestionView
    case completed
    case failed(Error)
}

// Equatable conformance is required for SwiftUI view comparisons/animations.
extension AnalysisState: Equatable {
    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.uploadingImage, .uploadingImage),
             (.analyzingFood, .analyzingFood),
             (.transformingData, .transformingData),
             (.fetchingAdvice, .fetchingAdvice),
             (.completed, .completed):
            return true
        case let (.failed(leftError), .failed(rightError)):
            let left = leftError as NSError
            let right = rightError as NSError
            return left.domain == right.domain
                && left.code == right.code
                && left.localizedDescription == right.localizedDescription
                && type(of: leftError) == type(of: rightError)
        default:
            return false
        }
    }
}

/// Custom analysis errors
enum AnalysisError: Error, LocalizedError {
    case noFoodDetected
    case partialSuccess(String)

    var errorDescription: String? {
        switch self {
        case .noFoodDetected:
            return "No food detected in the image. Please try again with a clearer photo."
        case .partialSuccess(let message):
            return message
        }
    }
}

@MainActor
class FoodAnalysisViewModel: ObservableObject {
    // MARK: - Published State

    @Published var state: AnalysisState = .idle
    @Published var dishes: [Dish] = []
    @Published var dietaryAdvice: DietaryAdviceResult?
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let foodAnalyzer: GeminiFoodImageAnalyzer
    private let dietaryAdvisor: GeminiDietaryAdvisor
    private var currentAnalysisResult: FoodAnalysisResult?
    private var capturedImage: UIImage?  // Store for meal persistence

    // MARK: - Initialization

    init(apiKey: String) {
        self.foodAnalyzer = GeminiFoodImageAnalyzer(apiKey: apiKey)
        self.dietaryAdvisor = GeminiDietaryAdvisor(apiKey: apiKey)
    }

    // MARK: - Main Analysis Flow

    /// Analyze food from captured image
    /// Orchestrates the complete flow: upload → analyze → transform → advise
    func analyzeFood(from image: UIImage) async {
        // Store image reference for meal persistence
        self.capturedImage = image

        do {
            // Phase 1: Upload image
            state = .uploadingImage
            let tempURL = try ModelTransformers.saveImageToTempFile(image)

            // Phase 2: Analyze food with Gemini
            state = .analyzingFood
            let analysisResult = try await foodAnalyzer.analyzeFoodImage(imageURL: tempURL)

            // Validate result
            guard !analysisResult.dishes.isEmpty else {
                throw AnalysisError.noFoodDetected
            }

            // Save for dietary advice
            currentAnalysisResult = analysisResult

            // Phase 3: Transform API models to UI models
            state = .transformingData
            dishes = ModelTransformers.transformToDishes(analysisResult)

            // Phase 4: Fetch dietary advice (background)
            state = .fetchingAdvice
            await fetchDietaryAdvice()

            // Phase 5: Complete
            state = .completed

            // Cleanup: Remove temporary file
            try? FileManager.default.removeItem(at: tempURL)

        } catch let error as FoodImageAnalyzerError {
            state = .failed(error)
            errorMessage = "Food analysis failed: \(error.localizedDescription)"
            print("Food analyzer error: \(error)")

        } catch let error as DietaryAdvisorError {
            // Partial success: we have dishes but no advice
            state = .completed
            errorMessage = "Dietary advice unavailable: \(error.localizedDescription)"
            print("Dietary advisor error: \(error)")

        } catch let error as AnalysisError {
            state = .failed(error)
            errorMessage = error.localizedDescription
            print("Analysis error: \(error)")

        } catch {
            state = .failed(error)
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            print("Unexpected error: \(error)")
        }
    }

    // MARK: - Private Helper Methods

    /// Fetch dietary advice from Gemini
    private func fetchDietaryAdvice() async {
        guard let analysisResult = currentAnalysisResult else {
            print("Warning: No analysis result available for dietary advice")
            return
        }

        do {
            let userProfile = UserProfileManager.shared.getProfile()
            let adviceInput = ModelTransformers.createDietaryAdviceInput(
                from: analysisResult,
                userProfile: userProfile
            )

            dietaryAdvice = try await dietaryAdvisor.getDietaryAdvice(input: adviceInput)
            print("✓ Dietary advice received successfully")

        } catch {
            print("⚠️ Failed to fetch dietary advice: \(error.localizedDescription)")
            // Don't fail the entire flow - user still has dish data
        }
    }

    // MARK: - Public Methods

    /// Reset to initial state
    func reset() {
        state = .idle
        dishes = []
        dietaryAdvice = nil
        errorMessage = nil
        currentAnalysisResult = nil
    }

    /// Retry analysis (for error recovery)
    func retry(with image: UIImage) async {
        reset()
        await analyzeFood(from: image)
    }

    // MARK: - Meal Persistence

    /// Save meal to persistent storage if dishes are available
    /// Also checks for new trophies after saving
    /// Returns newly earned trophies (if any)
    func saveMealIfNeeded() -> [Trophy] {
        guard !dishes.isEmpty else {
            print("⚠️ No dishes to save")
            return []
        }

        let mealType = MealPersistenceManager.determineMealType()

        do {
            try MealPersistenceManager.shared.saveMeal(
                timestamp: Date(),
                mealType: mealType,
                photo: capturedImage,
                dishes: dishes,
                dietaryAdvice: dietaryAdvice
            )
            print("✓ Meal saved successfully: \(mealType.rawValue)")

            // Check for new trophies after saving meal
            let newTrophies = TrophyManager.shared.checkForNewTrophies()
            if !newTrophies.isEmpty {
                print("🏆 \(newTrophies.count) new trophy(ies) earned!")
            }
            return newTrophies

        } catch {
            print("⚠️ Failed to save meal: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Cleanup

    deinit {
        // Clean up any remaining temp files
        cleanupTempFiles()
    }

    nonisolated private func cleanupTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil
        ) {
            for file in files where file.lastPathComponent.hasPrefix("food_") {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
