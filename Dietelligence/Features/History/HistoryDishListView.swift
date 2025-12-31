//
//  HistoryDishListView.swift
//  Dietelligence
//
//  Historical meal detail view - displays dishes, nutrition summary, and suggestions
//  Reuses existing components for consistency
//

import SwiftUI

struct HistoryDishListView: View {
    let meal: MealEntity
    let onDismiss: () -> Void
    @State private var showContent = false
    @State private var selectedDish: Dish?
    @Namespace private var heroAnimationNamespace

    // Convert MealEntity data to UI models
    private var dishes: [Dish] {
        meal.dishes.map { $0.toDish() }
    }

    private var allIngredients: [FoodIngredient] {
        dishes.flatMap { $0.ingredients }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.backGround)
            // Main content (only visible when no dish detail is shown)
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

                        // List of dish cards
                        VStack(spacing: 10) {
                            ForEach(dishes) { dish in
                                DishCardView(dish: dish, namespace: heroAnimationNamespace)
                                    .padding(.vertical, 10)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedDish = dish
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)

                        // Suggestion section (if advice exists)
                        if let advice = meal.dietaryAdvice {
                            HistorySuggestionView(advice: advice)
                        }
                    }
                }
                .scrollIndicators(.never)
                .opacity(showContent ? 1 : 0)
            }

            // Detail view overlay (when a dish is selected)
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
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                showContent = true
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Checkmark button (only visible when no dish detail is shown)
            if selectedDish == nil && showContent {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.mainEnable)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .padding(30)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    // Create sample MealEntity for preview
    let ingredient1 = IngredientEntity(
        name: "Chicken Breast",
        icon: "🍗",
        weight: 150,
        proteinPercent: 31,
        fatPercent: 3.6,
        carbohydratePercent: 0
    )

    let ingredient2 = IngredientEntity(
        name: "Rice",
        icon: "🍚",
        weight: 200,
        proteinPercent: 2.7,
        fatPercent: 0.3,
        carbohydratePercent: 28
    )

    let dish1 = DishEntity(
        name: "Grilled Chicken",
        icon: "🍗",
        ingredients: [ingredient1]
    )

    let dish2 = DishEntity(
        name: "White Rice",
        icon: "🍚",
        ingredients: [ingredient2]
    )

    let analysis = NutritionAnalysis(
        summary: "Balanced meal with good protein and moderate carbs.",
        nutritionStatus: "balanced",
        pros: ["High protein for muscle recovery", "Low fat content"],
        cons: ["Could use more vegetables"]
    )

    let recommendation = NextMealRecommendation(
        recommendedDish: RecommendedMealDish(
            dishName: "Salmon with Vegetables",
            icon: "🥗",
            weight: 300,
            proteinPercent: 25,
            fatPercent: 15,
            carbohydratePercent: 10
        ),
        reason: "Add omega-3 fats and fiber from vegetables.",
        nutrientsFocus: ["Omega-3 fatty acids", "Dietary fiber", "Vitamins"]
    )

    let advice = DietaryAdviceResult(
        analysis: analysis,
        nextMealRecommendation: recommendation
    )

    let meal = MealEntity(
        timestamp: Date(),
        mealType: .lunch,
        photo: nil,
        dishes: [dish1, dish2],
        dietaryAdvice: advice
    )

    return HistoryDishListView(meal: meal, onDismiss: {})
}
