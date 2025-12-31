//
//  GeminiNutritionPlanner.swift
//  Dietelligence
//
//  Gemini AI service for generating personalized daily nutrition targets
//  Based on user profile (weight, height, age, gender, activity level, goals)
//

import Foundation

class GeminiNutritionPlanner {

    // MARK: - Configuration

    private let apiKey: String
    private let modelName = "gemini-3-flash-preview"  // Latest model for better reasoning
    private let session: URLSession

    // MARK: - Initialization

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Public Methods

    /// Generate personalized nutrition targets based on user profile
    /// - Parameter profile: Complete user nutrition profile
    /// - Returns: NutritionTargetsResult with daily ranges for calories, protein, fat, and carbs
    func generateNutritionTargets(profile: UserNutritionProfile) async throws -> NutritionTargetsResult {
        print("🎯 Generating nutrition targets (Model: \(modelName))...")

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NutritionPlannerError.invalidURL
        }

        // Validate profile data
        guard profile.weight > 0, profile.height > 0, profile.age > 0 else {
            throw NutritionPlannerError.invalidProfile
        }

        // Create schema and payload
        let schema = getNutritionTargetsSchema()
        let payload = try createPlannerPayload(profile: profile, schema: schema)

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
                throw NutritionPlannerError.apiError(message: error.message)
            }
            throw NutritionPlannerError.requestFailed
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            throw NutritionPlannerError.noValidResponse
        }

        // Parse the JSON text into NutritionTargetsResult
        guard let jsonData = text.data(using: .utf8) else {
            throw NutritionPlannerError.invalidJSON
        }

        let result = try JSONDecoder().decode(NutritionTargetsResult.self, from: jsonData)
        print("✓ Nutrition targets generated successfully")
        return result
    }

    // MARK: - Private Methods

    private func getNutritionTargetsSchema() -> [String: Any] {
        return [
            "type": "OBJECT",
            "properties": [
                "daily_calories": [
                    "type": "OBJECT",
                    "properties": [
                        "min": ["type": "NUMBER", "description": "Minimum daily calories"],
                        "max": ["type": "NUMBER", "description": "Maximum daily calories"],
                        "target": ["type": "NUMBER", "description": "Target daily calories"]
                    ],
                    "required": ["min", "max", "target"]
                ],
                "daily_protein": [
                    "type": "OBJECT",
                    "properties": [
                        "min": ["type": "NUMBER", "description": "Minimum protein grams"],
                        "max": ["type": "NUMBER", "description": "Maximum protein grams"],
                        "target": ["type": "NUMBER", "description": "Target protein grams"]
                    ],
                    "required": ["min", "max", "target"]
                ],
                "daily_fat": [
                    "type": "OBJECT",
                    "properties": [
                        "min": ["type": "NUMBER", "description": "Minimum fat grams"],
                        "max": ["type": "NUMBER", "description": "Maximum fat grams"],
                        "target": ["type": "NUMBER", "description": "Target fat grams"]
                    ],
                    "required": ["min", "max", "target"]
                ],
                "daily_carbohydrate": [
                    "type": "OBJECT",
                    "properties": [
                        "min": ["type": "NUMBER", "description": "Minimum carbohydrate grams"],
                        "max": ["type": "NUMBER", "description": "Maximum carbohydrate grams"],
                        "target": ["type": "NUMBER", "description": "Target carbohydrate grams"]
                    ],
                    "required": ["min", "max", "target"]
                ],
                "explanation": [
                    "type": "STRING",
                    "description": "Brief explanation of the nutrition plan (2-3 sentences)"
                ]
            ],
            "required": ["daily_calories", "daily_protein", "daily_fat", "daily_carbohydrate", "explanation"]
        ]
    }

    private func createPlannerPayload(profile: UserNutritionProfile, schema: [String: Any]) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let profileData = try encoder.encode(profile)
        let profileJSONString = String(data: profileData, encoding: .utf8) ?? "{}"

        let prompt = """
        You are a professional certified nutritionist and registered dietitian. Analyze the following user profile and create a personalized daily nutrition plan.

        【User Profile】:
        \(profileJSONString)

        【Tasks】:
        1. Calculate TDEE (Total Daily Energy Expenditure) based on:
           - BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation:
             • Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age + 5
             • Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
           - Activity level multiplier:
             • Sedentary: BMR × 1.2
             • Lightly Active: BMR × 1.375
             • Moderately Active: BMR × 1.55
             • Active: BMR × 1.725
             • Very Active: BMR × 1.9
             • Extra Active: BMR × 2.0

        2. Adjust calorie target based on user goals:
           - "Lose Fat": -15% to -20% calorie deficit
           - "Gain Weight" or "Build Muscle": +10% to +15% calorie surplus
           - "Maintain Weight" or "General Fitness": TDEE ±5%
           - "Body Recomposition": TDEE to slight deficit (-5% to -10%)
           - "Improve Endurance" or "Increase Strength": TDEE +5% to +10%
           - Multiple goals: Prioritize the most specific goal

        3. Set macronutrient targets:
           - Protein: Based on goals
             • Muscle building: 1.6-2.2g per kg body weight
             • General fitness: 1.2-1.6g per kg body weight
             • Fat loss: 1.8-2.4g per kg body weight (preserve muscle)
           - Fat: 20-35% of total calories (minimum 0.8g per kg for hormonal health)
           - Carbohydrate: Remaining calories after protein and fat
             • Calories from carbs = Total calories - (Protein g × 4) - (Fat g × 9)
             • Carb grams = Carb calories ÷ 4

        4. Provide ranges (±10% from target) to allow flexibility
           - min = target × 0.9
           - max = target × 1.1

        5. Consider dietary preferences and restrictions mentioned in the profile

        6. Write a brief 2-3 sentence explanation of why these targets were chosen

        Output strictly following the JSON Schema. All numbers should be realistic and achievable.
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
                "temperature": 0.5  // Balanced for creative but consistent recommendations
            ]
        ]
    }
}

// MARK: - Error Types

enum NutritionPlannerError: Error, LocalizedError {
    case invalidURL
    case invalidProfile
    case requestFailed
    case noValidResponse
    case invalidJSON
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidProfile:
            return "Invalid user profile data (weight, height, or age is invalid)"
        case .requestFailed:
            return "Request failed"
        case .noValidResponse:
            return "No valid response received from Gemini API"
        case .invalidJSON:
            return "Invalid JSON response"
        case .apiError(let message):
            return "Gemini API Error: \(message)"
        }
    }
}
