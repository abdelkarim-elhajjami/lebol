import Foundation
import UIKit
import SwiftUI

// MARK: - Protocol for dependency injection and testability

protocol FoodAnalysisService: Sendable {
    func analyzePhotoStructured(_ image: UIImage) async throws -> StructuredMealResult
    func analyzeTextStructured(_ text: String) async throws -> StructuredMealResult
    func analyzeNutritionLabel(_ image: UIImage) async throws -> StructuredFoodResult
    func lookupFood(_ name: String) async throws -> [StructuredFoodResult]
    func interpretActivity(_ text: String, weightKg: Double) async throws -> ActivityInterpretation
}

// MARK: - SwiftUI Environment Key

struct FoodAnalysisServiceKey: EnvironmentKey {
    static let defaultValue: FoodAnalysisService = GeminiService.shared
}

extension EnvironmentValues {
    var foodAnalysisService: FoodAnalysisService {
        get { self[FoodAnalysisServiceKey.self] }
        set { self[FoodAnalysisServiceKey.self] = newValue }
    }
}

final class GeminiService: FoodAnalysisService, @unchecked Sendable {
    static let shared = GeminiService()

    private let apiKey = APIConfig.openRouterAPIKey
    private let model = "google/gemini-2.5-flash"
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    private init() {}

    // MARK: - OpenRouter API Types

    private struct OpenRouterRequest: Encodable {
        let model: String
        let temperature: Int
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: Content

            enum Content: Encodable {
                case text(String)
                case parts([ContentPart])

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    switch self {
                    case .text(let str): try container.encode(str)
                    case .parts(let parts): try container.encode(parts)
                    }
                }
            }
        }

        struct ContentPart: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?

            struct ImageURL: Encodable {
                let url: String
            }

            static func text(_ value: String) -> ContentPart {
                ContentPart(type: "text", text: value, image_url: nil)
            }

            static func image(mimeType: String, base64Data: String) -> ContentPart {
                ContentPart(type: "image_url", text: nil, image_url: ImageURL(url: "data:\(mimeType);base64,\(base64Data)"))
            }
        }
    }

    private struct OpenRouterResponse: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: Message
        }
        struct Message: Decodable {
            let content: String
        }
    }

    // MARK: - Shared Schema

    private let foodItemSchema = """
    Per ingredient, return this JSON structure:
    {
      "name": "food name in English",
      "calories_per_100g": number,
      "carbs_per_100g": number,
      "protein_per_100g": number,
      "fats_per_100g": number,
      "portion_description": "human-readable (e.g. 1 grilled breast)",
      "portion_grams": number (always in grams, even for liquids where 1ml ≈ 1g),
      "calories": number (for this portion),
      "carbs": number (for this portion),
      "protein": number (for this portion),
      "fats": number (for this portion),
      "unit": "g" | "ml" | "pcs",
      "unit_weight": number (grams per 1 piece when unit is "pcs", else 0)
    }

    Unit rules:
    - "g": solid foods
    - "ml": liquids (water, milk, juice, coffee, soup, broth)
    - "pcs": countable items (eggs, fruits, bread slices, cookies)

    Use USDA FoodData Central reference values for per-100g baselines.
    """

    // MARK: - Structured Food Photo Analysis

    func analyzePhotoStructured(_ image: UIImage) async throws -> StructuredMealResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw AIServiceError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        let systemPrompt = """
        Identify each food in this photo. For each, provide USDA-based per-100g nutrition and estimate the visible portion. Underestimate portions rather than overestimate.

        Return JSON: {"meal_name": "short summary", "ingredients": [<items>]}

        \(foodItemSchema)
        """

        let parts: [OpenRouterRequest.ContentPart] = [
            .image(mimeType: "image/jpeg", base64Data: base64Image),
            .text("Analyze this food photo and provide nutritional information.")
        ]

        let responseText = try await makeRequest(systemPrompt: systemPrompt, parts: parts)
        let cleaned = cleanJSON(responseText)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIServiceError.parsingError
        }
        return try JSONDecoder().decode(StructuredMealResult.self, from: data)
    }

    // MARK: - Structured Text Analysis

    func analyzeTextStructured(_ text: String) async throws -> StructuredMealResult {
        let systemPrompt = """
        Parse this food description. For each item, provide USDA-based per-100g nutrition. Use quantities from the input (e.g. "2 eggs" = 2 pcs). If no quantity given, estimate a typical single serving. Underestimate portions.

        Return JSON: {"meal_name": "short summary", "ingredients": [<items>]}

        \(foodItemSchema)
        """

        let parts: [OpenRouterRequest.ContentPart] = [
            .text(text)
        ]

        let responseText = try await makeRequest(systemPrompt: systemPrompt, parts: parts)
        let cleaned = cleanJSON(responseText)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIServiceError.parsingError
        }
        return try JSONDecoder().decode(StructuredMealResult.self, from: data)
    }

    // MARK: - Nutrition Label OCR

    func analyzeNutritionLabel(_ image: UIImage) async throws -> StructuredFoodResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw AIServiceError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        let systemPrompt = """
        Extract nutrition facts exactly as printed on this label. Do not estimate — read values from the label. If label shows per-serving, convert to per-100g using the serving size. Use product name if visible, otherwise "Unknown Product".

        Return a single JSON object (not array):

        \(foodItemSchema)
        """

        let parts: [OpenRouterRequest.ContentPart] = [
            .image(mimeType: "image/jpeg", base64Data: base64Image),
            .text("Read the nutrition facts from this food label.")
        ]

        let responseText = try await makeRequest(systemPrompt: systemPrompt, parts: parts)
        let cleaned = cleanJSON(responseText)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIServiceError.parsingError
        }
        return try JSONDecoder().decode(StructuredFoodResult.self, from: data)
    }

    // MARK: - AI-Powered Food Search

    func lookupFood(_ name: String) async throws -> [StructuredFoodResult] {
        let systemPrompt = """
        Return up to 5 foods matching this search with USDA-based per-100g nutrition and a typical serving. Include common variations (e.g. "Egg", "Egg White", "Boiled Egg").

        Return JSON array: [<items>]

        \(foodItemSchema)
        """

        let parts: [OpenRouterRequest.ContentPart] = [
            .text(name)
        ]

        let responseText = try await makeRequest(systemPrompt: systemPrompt, parts: parts)
        let cleaned = cleanJSON(responseText)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIServiceError.parsingError
        }
        return try JSONDecoder().decode([StructuredFoodResult].self, from: data)
    }

    // MARK: - Interpret Activity

    func interpretActivity(_ text: String, weightKg: Double) async throws -> ActivityInterpretation {
        let systemPrompt = """
        Parse the user's activity description. Extract the activity name and duration.
        Map to the closest MET value from the 2011 Compendium of Physical Activities.
        Calculate calories: MET × \(weightKg) kg × (duration_minutes / 60).
        Return JSON: { "activity": "...", "met": ..., "durationMinutes": ..., "caloriesBurned": ... }
        If duration not specified, assume 30 minutes.
        Return ONLY the JSON, no other text.
        """

        let parts: [OpenRouterRequest.ContentPart] = [
            .text(text)
        ]

        let responseText = try await makeRequest(systemPrompt: systemPrompt, parts: parts)
        let cleaned = cleanJSON(responseText)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIServiceError.parsingError
        }
        return try JSONDecoder().decode(ActivityInterpretation.self, from: data)
    }

    // MARK: - Private Helpers

    private func makeRequest(systemPrompt: String, parts: [OpenRouterRequest.ContentPart]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let body = OpenRouterRequest(
            model: model,
            temperature: 0,
            messages: [
                .init(role: "system", content: .text(systemPrompt + "\n\nReturn ONLY valid JSON, no markdown or code blocks.")),
                .init(role: "user", content: .parts(parts))
            ]
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = apiResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanJSON(_ text: String) -> String {
        var cleaned = text
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
