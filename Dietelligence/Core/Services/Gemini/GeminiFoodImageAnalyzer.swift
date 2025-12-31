//
//  GeminiFoodImageAnalyzer.swift
//  Dietelligence
//
//  Food image analysis using Gemini 2.5 Flash
//  Swift equivalent of net.py
//

import Foundation
import UniformTypeIdentifiers

class GeminiFoodImageAnalyzer {

    // MARK: - Configuration

    private let apiKey: String
    private let modelName = "gemini-3-flash-preview"
    private let session: URLSession

    // MARK: - Initialization

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Public Methods

    /// Analyze food image and return structured nutrition data
    /// - Parameter imageURL: Local file URL of the image
    /// - Returns: FoodAnalysisResult containing dishes and ingredients
    func analyzeFoodImage(imageURL: URL) async throws -> FoodAnalysisResult {
        // 1. Upload file
        print("📤 [1/3] Uploading image...")
        let (fileURI, mimeType) = try await uploadFile(imageURL: imageURL)
        print("✅ [1/3] Upload successful: \(fileURI)")

        // 2. Analyze with Gemini
        print("🤖 [2/3] Requesting nutritional analysis from \(modelName)...")
        let result = try await analyzeWithGemini(fileURI: fileURI, mimeType: mimeType)
        print("✅ [2/3] Analysis complete!")

        return result
    }

    // MARK: - Private Methods - File Upload

    private func uploadFile(imageURL: URL) async throws -> (fileURI: String, mimeType: String) {
        // Determine MIME type
        let mimeType = getMimeType(for: imageURL)

        guard let fileData = try? Data(contentsOf: imageURL) else {
            throw FoodImageAnalyzerError.fileReadError
        }

        let fileSize = fileData.count
        print("📤 File size: \(Double(fileSize) / 1024.0) KB, MIME: \(mimeType)")

        // Step 1: Initialize resumable upload
        let uploadURL = try await initializeUpload(
            fileName: imageURL.lastPathComponent,
            fileSize: fileSize,
            mimeType: mimeType
        )

        // Step 2: Upload file data
        let fileURI = try await uploadFileData(
            uploadURL: uploadURL,
            fileData: fileData,
            fileSize: fileSize
        )

        return (fileURI, mimeType)
    }

    private func initializeUpload(fileName: String, fileSize: Int, mimeType: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/upload/v1beta/files?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw FoodImageAnalyzerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        request.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        request.setValue("\(fileSize)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        request.setValue(mimeType, forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "file": [
                "display_name": fileName
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Upload initialization failed: Invalid response type")
            throw FoodImageAnalyzerError.uploadInitializationFailed
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Upload initialization failed - Status: \(httpResponse.statusCode)")
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ Response: \(responseBody)")
            }
            throw FoodImageAnalyzerError.uploadInitializationFailed
        }

        guard let uploadURL = httpResponse.value(forHTTPHeaderField: "X-Goog-Upload-URL") else {
            print("❌ Upload initialization failed: Missing X-Goog-Upload-URL header")
            print("❌ Headers: \(httpResponse.allHeaderFields)")
            throw FoodImageAnalyzerError.uploadInitializationFailed
        }

        return uploadURL
    }

    private func uploadFileData(uploadURL: String, fileData: Data, fileSize: Int) async throws -> String {
        guard let url = URL(string: uploadURL) else {
            throw FoodImageAnalyzerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        request.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        request.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        request.httpBody = fileData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ File upload failed: Invalid response type")
            throw FoodImageAnalyzerError.uploadFailed
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ File upload failed - Status: \(httpResponse.statusCode)")
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ Response: \(responseBody)")
            }
            throw FoodImageAnalyzerError.uploadFailed
        }

        let uploadResponse = try JSONDecoder().decode(FileUploadCompleteResponse.self, from: data)
        return uploadResponse.file.uri
    }

    // MARK: - Private Methods - Gemini Analysis

    private func analyzeWithGemini(fileURI: String, mimeType: String) async throws -> FoodAnalysisResult {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw FoodImageAnalyzerError.invalidURL
        }

        let schema = getFoodAnalysisSchema()
        let payload = createAnalysisPayload(fileURI: fileURI, mimeType: mimeType, schema: schema)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Analysis request failed: Invalid response type")
            throw FoodImageAnalyzerError.analysisRequestFailed
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Analysis request failed - Status: \(httpResponse.statusCode)")
            // Try to parse error
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let error = errorResponse.error {
                print("❌ API Error: \(error.message)")
                throw FoodImageAnalyzerError.apiError(message: error.message)
            }
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ Response: \(responseBody.prefix(500))")
            }
            throw FoodImageAnalyzerError.analysisRequestFailed
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            throw FoodImageAnalyzerError.noValidResponse
        }

        // Parse the JSON text into FoodAnalysisResult
        guard let jsonData = text.data(using: .utf8) else {
            throw FoodImageAnalyzerError.invalidJSON
        }

        let result = try JSONDecoder().decode(FoodAnalysisResult.self, from: jsonData)
        return result
    }

    // MARK: - Helper Methods

    private func getMimeType(for url: URL) -> String {
        if let utType = UTType(filenameExtension: url.pathExtension),
           let mimeType = utType.preferredMIMEType {
            return mimeType
        }
        return "image/jpeg" // Default fallback
    }

    private func getFoodAnalysisSchema() -> [String: Any] {
        return [
            "type": "OBJECT",
            "properties": [
                "dish_num": [
                    "type": "INTEGER",
                    "description": "Total number of distinct dishes identified"
                ],
                "dishes": [
                    "type": "ARRAY",
                    "description": "List of dishes",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "dish_name": ["type": "STRING", "description": "Name of the dish"],
                            "icon": ["type": "STRING", "description": "Emoji icon representing the dish(only one)"],
                            "ingredients": [
                                "type": "ARRAY",
                                "items": [
                                    "type": "OBJECT",
                                    "properties": [
                                        "name": ["type": "STRING", "description": "Ingredient name"],
                                        "icon": ["type": "STRING", "description": "Emoji icon representing the ingredient(only one)"],
                                        "weight": ["type": "NUMBER", "description": "Estimated weight in grams"],
                                        "proteinPercent": ["type": "NUMBER", "description": "Protein percentage (0-100)"],
                                        "fatPercent": ["type": "NUMBER", "description": "Fat percentage (0-100)"],
                                        "carbohydratePercent": ["type": "NUMBER", "description": "Carbohydrate percentage (0-100)"]
                                    ],
                                    "required": ["name", "icon", "weight", "proteinPercent", "fatPercent", "carbohydratePercent"]
                                ]
                            ]
                        ],
                        "required": ["dish_name","icon", "ingredients"]
                    ]
                ]
            ],
            "required": ["dish_num", "dishes"]
        ]
    }

    private func createAnalysisPayload(fileURI: String, mimeType: String, schema: [String: Any]) -> [String: Any] {
        return [
            "contents": [
                [
                    "parts": [
                        [
                            "file_data": [
                                "mime_type": mimeType,
                                "file_uri": fileURI
                            ]
                        ],
                        [
                            "text": "Analyze the food in this image. If it contains complex dishes, please break down the ingredients. Provide professional macronutrient estimates for each ingredient."
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "response_schema": schema,
                "temperature": 0.2
            ]
        ]
    }
}

// MARK: - Error Types

enum FoodImageAnalyzerError: Error, LocalizedError {
    case fileReadError
    case invalidURL
    case uploadInitializationFailed
    case uploadFailed
    case analysisRequestFailed
    case noValidResponse
    case invalidJSON
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .fileReadError:
            return "Unable to read image file"
        case .invalidURL:
            return "Invalid URL"
        case .uploadInitializationFailed:
            return "File upload initialization failed"
        case .uploadFailed:
            return "File upload failed"
        case .analysisRequestFailed:
            return "Analysis request failed"
        case .noValidResponse:
            return "No valid response received"
        case .invalidJSON:
            return "Invalid JSON response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
