//
//  SuggestionView.swift
//  Dietelligence
//
//  Main container for meal suggestions and daily review
//

import SwiftUI

struct SuggestionView: View {
    @EnvironmentObject var viewModel: FoodAnalysisViewModel

    var body: some View {
        ZStack{
            Color.backGround
            VStack{
                NextMealRecommendationView()
                    .padding(.bottom)
                SuggestionSummaryView()
                Rectangle()
                    .fill(.mainText)
                    .frame(height: 3)
                    .padding(.top)
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    @Previewable @StateObject var viewModel = FoodAnalysisViewModel(apiKey: "test-key")

    return SuggestionView()
        .environmentObject(viewModel)
}
