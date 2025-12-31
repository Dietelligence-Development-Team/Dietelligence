//
//  APISettingView.swift
//  Dietelligence
//
//  Created by Cosmos on 30/12/2025.
//

import SwiftUI

struct APISettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var onDismiss: (() -> Void)? = nil  // 可选的dismiss回调

    @State private var apiKey: String = ""
    @State private var originalKey: String? = nil  // 保存原始key
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSaving: Bool = false
    @State private var showSuccess: Bool = false

    var body: some View {
        ZStack{
            Rectangle()
                .fill(.backGround)
            VStack{
                Spacer()
                    .frame(height: 80)

                Text("AI Setting")
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .foregroundStyle(.mainText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text("Dietelligence uses `gemini-3-flash` as the core,\n we need the api key here to start using it")
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .foregroundStyle(.mainText)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity,alignment: .leading)

                Rectangle()
                    .fill(.mainText)
                    .frame(height: 3)

                CustomTextField(title: "API Key", placeholder: "AIzaSy...", text: $apiKey)
                    .padding(.vertical, 5)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                Rectangle()
                    .fill(.mainText)
                    .frame(height: 3)

                Text("This key will be stored encrypted locally using iOS Keychain. You can get a key from here: [Using Gemini API keys](https://ai.google.dev/gemini-api/docs/api-key)")
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .fontWeight(.semibold)
                    .foregroundStyle(.mainText)
                    .frame(maxWidth: .infinity,alignment: .leading)

                // Error Message
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Success Message
                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("API key saved successfully!")
                    }
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.top, 8)
                }

                Spacer()

                Button {
                    saveAPIKey()
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .userEnable))
                            .frame(width: 80)
                    } else {
                        Text("Done")
                            .fontDesign(.serif)
                            .fontWeight(.bold)
                            .foregroundStyle(.userEnable)
                            .padding(5)
                            .frame(width: 80)
                    }
                }
                .buttonStyle(.glass)
                .disabled(apiKey.isEmpty || isSaving)

                Spacer()
                    .frame(height: 80)

            }
            .padding()
        }
        .ignoresSafeArea()
        .onAppear {
            loadExistingKey()
        }
    }

    // MARK: - Private Methods

    private func loadExistingKey() {
        // Pre-populate with existing key if available
        if let existingKey = GeminiConfiguration.apiKey {
            // Save original key
            originalKey = existingKey
            // Show masked version for security
            apiKey = maskAPIKey(existingKey)
        }
    }

    private func maskAPIKey(_ key: String) -> String {
        // Show first 8 characters and last 4 for identification
        guard key.count > 12 else { return key }
        let start = key.prefix(8)
        let end = key.suffix(4)
        return "\(start)...\(end)"
    }

    private func saveAPIKey() {
        // Reset states
        showError = false
        showSuccess = false

        // Check if this is the masked original key (unchanged)
        if let original = originalKey, apiKey == maskAPIKey(original) {
            // No changes made, just dismiss
            dismissView()
            return
        }

        // Validate API key format
        guard validateAPIKey(apiKey) else {
            errorMessage = "Invalid API key format. Google API keys typically start with 'AIza' and are 39 characters long."
            showError = true
            return
        }

        isSaving = true

        // Save to Keychain
        Task {
            do {
                try GeminiConfiguration.saveAPIKey(apiKey)

                await MainActor.run {
                    isSaving = false
                    showSuccess = true

                    // Refresh app state
                    appState.refreshAPIKeyStatus()

                    // Dismiss after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismissView()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save API key: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func dismissView() {
        // 优先使用回调，否则使用Environment的dismiss
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func validateAPIKey(_ key: String) -> Bool {
        // Google Gemini API keys have specific format:
        // - Start with "AIza"
        // - Typically 39 characters long
        // - Alphanumeric with some special characters

        let trimmedKey = key.trimmingCharacters(in: .whitespaces)

        // Basic validation
        guard !trimmedKey.isEmpty else { return false }
        guard trimmedKey.hasPrefix("AIza") else { return false }
        guard trimmedKey.count >= 35 && trimmedKey.count <= 45 else { return false }

        // Only allow alphanumeric and common API key characters
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "-_"))
        let keyCharacters = CharacterSet(charactersIn: trimmedKey)

        return allowedCharacters.isSuperset(of: keyCharacters)
    }
}

#Preview {
    APISettingView()
}
