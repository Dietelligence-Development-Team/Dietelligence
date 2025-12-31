//
//  DishListView.swift
//  Dietelligence
//
//  菜品列表视图 - 显示所有菜品并支持导航到详情
//

import SwiftUI

struct DishListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: FoodAnalysisViewModel
    @State private var animatedDishes: [Dish] = []
    @State private var showSuggestion = false
    @State private var selectedDish: Dish?
    @Namespace private var heroAnimationNamespace

    // Trophy popup state
    @State private var earnedTrophies: [Trophy] = []
    @State private var showTrophyPopup: Bool = false
    @State private var currentTrophyIndex: Int = 0

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
    }

    var body: some View {
        ZStack {
            // Main list view
            if selectedDish == nil {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)

                        // Aggregated nutrition for ALL dishes
                        NutritionSummaryView(
                            ingredients: allIngredients,
                            title: "All Dishes"
                        )
                        .padding(.horizontal, 10)

                        // List of dish cards (animated)
                        VStack(spacing: 10) {
                            ForEach(Array(animatedDishes.enumerated()), id: \.element.id) { index, dish in
                                DishCardView(dish: dish, namespace: heroAnimationNamespace)
                                    .padding(.vertical, 10)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedDish = dish
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)

                        if showSuggestion {
                            if viewModel.dietaryAdvice != nil {
                                SuggestionView()
                            } else {
                                analyzingFooter
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
            }

            // Detail view overlay
            if let dish = selectedDish {
                DishDetailView(
                    dish: dish,
                    namespace: heroAnimationNamespace,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            selectedDish = nil
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.dishes) { _, newDishes in
            animateDishesAppearing(newDishes)
        }
        .onAppear {
            // If dishes were loaded before the view appeared (e.g., fast network),
            // ensure they still animate into view.
            if animatedDishes.isEmpty && !viewModel.dishes.isEmpty {
                animateDishesAppearing(viewModel.dishes)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedDish == nil {
                Button {
                    // Save meal and check for trophies
                    let newTrophies = viewModel.saveMealIfNeeded()
                    if !newTrophies.isEmpty {
                        earnedTrophies = newTrophies
                        currentTrophyIndex = 0
                        showTrophyPopup = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .frame(width: 40,height: 40)
                        .foregroundStyle(.mainEnable)
                        .glassEffect(.regular.interactive(),in: Circle())
                }
                .padding(30)
            }
        }
        .overlay {
            // Trophy popup overlay
            if showTrophyPopup, currentTrophyIndex < earnedTrophies.count {
                TrophyPopupView(
                    trophy: earnedTrophies[currentTrophyIndex],
                    onDismiss: {
                        if currentTrophyIndex < earnedTrophies.count - 1 {
                            // Show next trophy
                            currentTrophyIndex += 1
                        } else {
                            // All trophies shown, dismiss the view
                            showTrophyPopup = false
                            earnedTrophies = []
                            currentTrophyIndex = 0
                            dismiss()
                        }
                    }
                )
            }
        }
        .ignoresSafeArea()
    }

    private var analyzingFooter: some View {
        TypingAnimationText(fullText: "Analyzing...")
            .frame(height: 20)
            .padding(.bottom, 12)
    }

    // MARK: - Helper Properties

    /// Combine all ingredients from all dishes for aggregated nutrition summary
    private var allIngredients: [FoodIngredient] {
        animatedDishes.flatMap { $0.ingredients }
    }

    // MARK: - Helper Methods

    /// Animate dishes appearing one by one
    private func animateDishesAppearing(_ dishes: [Dish]) {
        // Skip staged animations in preview to avoid slow rendering timeouts
        if isPreview {
            animatedDishes = dishes
            showSuggestion = true
            return
        }

        animatedDishes = []
        for (index, dish) in dishes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    animatedDishes.append(dish)
                }
            }
        }

        // Show suggestion after dishes finish appearing
        let delay = Double(dishes.count) * 0.2 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation {
                showSuggestion = true
            }
        }
    }
}

#Preview {
    DishListPreviewWrapper()
}

private struct DishListPreviewWrapper: View {
    @StateObject private var viewModel: FoodAnalysisViewModel

    init() {
        let vm = FoodAnalysisViewModel(apiKey: "test-key")
        _viewModel = StateObject(wrappedValue: vm)

        // Seed sample data on the main actor to avoid preview delays
        Task { @MainActor in
            vm.dishes = Dish.sampleData
            vm.state = .completed
            vm.dietaryAdvice = .sample
        }
    }

    var body: some View {
        DishListView()
            .environmentObject(viewModel)
    }
}

// Preview-only sample data
fileprivate extension DietaryAdviceResult {
    static var sample: DietaryAdviceResult {
        let analysis = NutritionAnalysis(
            summary: "Overall balanced meal with room to boost fiber and control sodium.",
            nutritionStatus: "balanced",
            pros: [
                "Good protein coverage for recovery",
                "Healthy fats in a reasonable range"
            ],
            cons: [
                "Fiber is lower than daily target",
                "Sodium likely high from sauces"
            ]
        )

        let recommendation = NextMealRecommendation(
            recommendedDish: RecommendedMealDish(
                dishName: "Grilled Salmon with Quinoa & Greens",
                icon: "🥗",
                weight: 320,
                proteinPercent: 28,
                fatPercent: 15,
                carbohydratePercent: 40
            ),
            reason: "Balances previous meal by adding fiber-rich grains and leafy greens while keeping protein steady.",
            nutrientsFocus: [
                "Increase dietary fiber",
                "Control sodium intake",
                "Maintain lean protein"
            ]
        )

        return DietaryAdviceResult(
            analysis: analysis,
            nextMealRecommendation: recommendation
        )
    }
}

 
