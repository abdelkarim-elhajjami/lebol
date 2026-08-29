import Foundation
import SwiftData

enum ServingUnit: String, Codable, CaseIterable {
    case grams = "g"
    case milliliters = "ml"
    case pieces = "pcs"
}

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var servingSize: String
    var servingGrams: Double
    var calories: Double
    var carbs: Double
    var protein: Double
    var fats: Double
    var caloriesPer100g: Double
    var carbsPer100g: Double
    var proteinPer100g: Double
    var fatsPer100g: Double
    // Unused — kept for SwiftData schema compatibility (removing columns requires custom migration)
    var source: String
    var servingUnit: ServingUnit
    var unitWeight: Double

    init(
        name: String,
        servingSize: String = "1 serving",
        servingGrams: Double = 100,
        calories: Double,
        carbs: Double,
        protein: Double,
        fats: Double,
        caloriesPer100g: Double = 0,
        carbsPer100g: Double = 0,
        proteinPer100g: Double = 0,
        fatsPer100g: Double = 0,
        source: String = "estimated",
        servingUnit: ServingUnit = .grams,
        unitWeight: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.servingSize = servingSize
        self.servingGrams = servingGrams
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fats = fats
        self.caloriesPer100g = caloriesPer100g
        self.carbsPer100g = carbsPer100g
        self.proteinPer100g = proteinPer100g
        self.fatsPer100g = fatsPer100g
        self.source = source
        self.servingUnit = servingUnit
        self.unitWeight = unitWeight
    }

    var displayQuantity: Double {
        switch servingUnit {
        case .pieces where unitWeight > 0: return servingGrams / unitWeight
        default: return servingGrams
        }
    }

    var displayUnitLabel: String {
        switch servingUnit {
        case .milliliters: return "ml"
        case .pieces: return "pcs"
        case .grams: return "g"
        }
    }
}
