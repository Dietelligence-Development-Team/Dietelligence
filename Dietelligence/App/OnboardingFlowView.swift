//
//  OnboardingFlowView.swift
//  Dietelligence
//
//  Guides first-time users through name capture then full profile.
//

import SwiftUI

private enum OnboardingStep {
    case welcome
    case info(name: String)
}

struct OnboardingFlowView: View {
    @State private var step: OnboardingStep = .welcome

    let onFinished: () -> Void

    var body: some View {
        VStack{
            switch step {
            case .welcome:
                WelcomeView { name in
                    step = .info(name: name)
                }
            case .info(let name):
                InfoView(initialName: name, onFinished: {
                    onFinished()
                }, showResetButton: false)
            }
        }
        .background(.backGround)
        .ignoresSafeArea()
        
    }
}

#Preview {
    OnboardingFlowView { }
}
