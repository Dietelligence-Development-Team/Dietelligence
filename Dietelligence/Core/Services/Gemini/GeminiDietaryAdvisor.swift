//
//  GeminiDietaryAdvisor.swift
//  Dietelligence
//
//  Dietary advice and meal recommendations using Gemini 2.5 Flash
//  Swift equivalent of advice.py
//

import Foundation

class GeminiDietaryAdvisor {

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

    /// Get dietary advice based on user's meal data and profile
    /// - Parameter input: Complete dietary data including meal info, 3-day average, and user profile
    /// - Returns: DietaryAdviceResult containing analysis and next meal recommendation
    func getDietaryAdvice(input: DietaryAdviceInput) async throws -> DietaryAdviceResult {
        print("🧠 Analyzing dietary data (Model: \(modelName))...")

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw DietaryAdvisorError.invalidURL
        }

        // Create schema and payload
        let schema = getDietaryAdviceSchema()
        let payload = try createAdvicePayload(input: input, schema: schema)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let error = errorResponse.error {
                throw DietaryAdvisorError.apiError(message: error.message)
            }
            throw DietaryAdvisorError.requestFailed
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            throw DietaryAdvisorError.noValidResponse
        }

        // Parse the JSON text into DietaryAdviceResult
        guard let jsonData = text.data(using: .utf8) else {
            throw DietaryAdvisorError.invalidJSON
        }

        let result = try JSONDecoder().decode(DietaryAdviceResult.self, from: jsonData)
        return result
    }

    // MARK: - Private Methods

    private func getDietaryAdviceSchema() -> [String: Any] {
        return [
            "type": "OBJECT",
            "properties": [
                "analysis": [
                    "type": "OBJECT",
                    "properties": [
                        "summary": [
                            "type": "STRING",
                            "description": "Short evaluation (under 50 words)"
                        ],
                        "nutrition_status": [
                            "type": "STRING",
                            "description": "Nutritional status, e.g., 'Protein deficiency', 'Carb overload', or 'Balanced'"
                        ],
                        "pros": [
                            "type": "ARRAY",
                            "items": ["type": "STRING"],
                            "description": "Pros of this meal"
                        ],
                        "cons": [
                            "type": "ARRAY",
                            "items": ["type": "STRING"],
                            "description": "Cons of this meal"
                        ]
                    ],
                    "required": ["summary", "nutrition_status", "pros", "cons"]
                ],
                "next_meal_recommendation": [
                    "type": "OBJECT",
                    "properties": [
                        "recommended_dish": [
                            "type": "OBJECT",
                            "description": "Details of the recommended next meal",
                            "properties": [
                                "dish_name": ["type": "STRING", "description": "Dish name"],
                                "icon": ["type": "STRING", "description": "Emoji icon (only one)"],
                                "weight": ["type": "NUMBER", "description": "Weight (grams)"],
                                "proteinPercent": ["type": "NUMBER", "description": "Protein percentage (0-100)"],
                                "fatPercent": ["type": "NUMBER", "description": "Fat percentage (0-100)"],
                                "carbohydratePercent": ["type": "NUMBER", "description": "Carbohydrate percentage (0-100)"]
                            ],
                            "required": ["dish_name", "icon", "weight", "proteinPercent", "fatPercent", "carbohydratePercent"]
                        ],
                        "reason": [
                            "type": "STRING",
                            "description": "Reason for recommendation, combining 3-day trends and user goals"
                        ],
                        "nutrients_focus": [
                            "type": "ARRAY",
                            "items": ["type": "STRING"],
                            "description": "Nutrients to focus on or control (e.g., 'Increase fiber', 'Control sodium')"
                        ]
                    ],
                    "required": ["recommended_dish", "reason", "nutrients_focus"]
                ]
            ],
            "required": ["analysis", "next_meal_recommendation"]
        ]
    }

    private func createAdvicePayload(input: DietaryAdviceInput, schema: [String: Any]) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let inputData = try encoder.encode(input)

        let inputJSONString = String(data: inputData, encoding: .utf8) ?? "{}"

        // Build dynamic context description
        let historyContext: String
        if let avg = input.nutritionAverage {
            historyContext = "\(avg.daysCovered)-day average intake (based on \(avg.mealCount) meals)"
        } else {
            historyContext = "no historical data available"
        }

        let prompt = """
        You are a top-tier professional private nutritionist. Please analyze the following JSON data (containing the user's current meal, \(historyContext), and user profile).

        【Input Data】:
        \(inputJSONString)

        【Tasks】:
        1. Analyze whether the nutritional structure of this meal aligns with the user's goal and physical condition.
        2. \(input.nutritionAverage != nil ? "Combine with the historical average data (nutrition_average) to determine if there is any long-term nutritional deficit or surplus." : "Since there is no historical data, focus on the current meal's nutritional balance.")
        3. Based on the current time (kind) and intake, provide specific recommendations for the "next meal" to balance the day's nutrition.
        4. If the user has any dietary restrictions or allergies, strictly avoid them in the recommendations.

        Please output strictly following the JSON Schema.
        """

        return [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "response_schema": schema,
                "temperature": 0.3
            ]
        ]
    }
}

// MARK: - Error Types

enum DietaryAdvisorError: Error, LocalizedError {
    case invalidURL
    case invalidInputData
    case requestFailed
    case noValidResponse
    case invalidJSON
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidInputData:
            return "Invalid input data"
        case .requestFailed:
            return "Request failed"
        case .noValidResponse:
            return "No valid response received"
        case .invalidJSON:
            return "Invalid JSON response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
