import Foundation

// MARK: - Error Types

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidImage
    case invalidResponse
    case parsingError
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "AI features are not configured. Add your OpenRouter API key in Settings."
        case .invalidURL: return "Invalid API URL."
        case .invalidImage: return "Could not process the image."
        case .invalidResponse: return "Invalid response from API."
        case .parsingError: return "Could not parse the AI response."
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        }
    }
}

// MARK: - Structured Response Types (per-100g)

struct StructuredFoodResult: Codable, Identifiable {
    let id: UUID
    let name: String
    let caloriesPer100g: Double
    let carbsPer100g: Double
    let proteinPer100g: Double
    let fatsPer100g: Double
    let portionDescription: String
    let portionGrams: Double
    let calories: Double
    let carbs: Double
    let protein: Double
    let fats: Double
    let unit: String?
    let unitWeight: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.caloriesPer100g = try container.decode(Double.self, forKey: .caloriesPer100g)
        self.carbsPer100g = try container.decode(Double.self, forKey: .carbsPer100g)
        self.proteinPer100g = try container.decode(Double.self, forKey: .proteinPer100g)
        self.fatsPer100g = try container.decode(Double.self, forKey: .fatsPer100g)
        self.portionDescription = try container.decode(String.self, forKey: .portionDescription)
        self.portionGrams = try container.decode(Double.self, forKey: .portionGrams)
        self.calories = try container.decode(Double.self, forKey: .calories)
        self.carbs = try container.decode(Double.self, forKey: .carbs)
        self.protein = try container.decode(Double.self, forKey: .protein)
        self.fats = try container.decode(Double.self, forKey: .fats)
        self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
        self.unitWeight = try container.decodeIfPresent(Double.self, forKey: .unitWeight)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case caloriesPer100g = "calories_per_100g"
        case carbsPer100g = "carbs_per_100g"
        case proteinPer100g = "protein_per_100g"
        case fatsPer100g = "fats_per_100g"
        case portionDescription = "portion_description"
        case portionGrams = "portion_grams"
        case calories, carbs, protein, fats
        case unit
        case unitWeight = "unit_weight"
    }

    var resolvedUnit: String { unit ?? "g" }
    var resolvedUnitWeight: Double { unitWeight ?? 0 }
}

struct StructuredMealResult: Codable {
    let mealName: String
    let ingredients: [StructuredFoodResult]

    enum CodingKeys: String, CodingKey {
        case mealName = "meal_name"
        case ingredients
    }
}

// MARK: - Activity Interpretation

struct ActivityInterpretation: Codable {
    let activity: String
    let met: Double
    let durationMinutes: Int
    let caloriesBurned: Int
}
