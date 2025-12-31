//
//  HistoryList.swift
//  Dietelligence
//
//  Created by Cosmos on 27/12/2025.
//

import SwiftUI

struct HistoryList: View {
    @State private var meals: [MealEntity] = []
    @Binding var selectedMeal: MealEntity?

    var body: some View {
        Group{
            if meals.isEmpty {
                VStack(spacing: 20) {
                    Text("No meal history yet")
                        .font(.system(.title3, design: .serif, weight: .medium))
                        .foregroundStyle(.mainText.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
                .listRowBackground(Color.clear)
            } else {
                List {
                    ForEach(meals, id: \.id) { meal in
                        Button {
                            selectedMeal = meal
                        } label: {
                            HistoryRow(
                                protein: meal.totalProtein,
                                fat: meal.totalFat,
                                carbon: meal.totalCarbohydrate,
                                timestamp: meal.timestamp,
                                dishIcons: meal.dishes.map { $0.icon }
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.backGround)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Rectangle().fill(.backGround))
        .ignoresSafeArea()
        .onAppear {
            loadMeals()
        }
        .refreshable {
            loadMeals()
        }
    }

    private func loadMeals() {
        meals = MealPersistenceManager.shared.fetchRecentMeals(limit: 50)
        print("✓ Loaded \(meals.count) meals from history")
    }
}

#Preview {
    HistoryList(selectedMeal: .constant(nil))
}
