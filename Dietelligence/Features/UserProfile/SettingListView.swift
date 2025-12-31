//
//  SettingListView.swift
//  Dietelligence
//
//  Created by Cosmos on 30/12/2025.
//

import SwiftUI

struct SettingListView: View {
    var body: some View {
        NavigationStack {
            List {
                // Profile Navigation
                NavigationLink {
                    InfoView(
                        initialName: UserProfileManager.shared.getProfile().name,
                        onFinished: {},
                        showResetButton: true
                    )
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Profile")
                        Spacer()
                    }
                }
                .listRowBackground(Color.backGround)

                // AI Settings Navigation
                NavigationLink {
                    APISettingView()
                } label: {
                    HStack {
                        Image(systemName: "sparkle")
                        Text("AI Settings")
                        Spacer()

                        // Show status indicator
                        if GeminiConfiguration.hasAPIKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .imageScale(.small)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .imageScale(.small)
                        }
                    }
                }
                .listRowBackground(Color.backGround)
            }
            
            .listStyle(.plain)
            .font(.title2)
            .fontDesign(.serif)
            .fontWeight(.bold)
            .foregroundStyle(.mainText)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingListView()
}
