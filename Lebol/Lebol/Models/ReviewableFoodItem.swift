import Foundation

// MARK: - Reviewable Food Item (adapter between AI responses and SwiftData models)

struct ReviewableFoodItem: Identifiable {
    let id: UUID
    var name: String
    var servingSize: String
    var servingGrams: Double
    var caloriesPer100g: Double
    var carbsPer100g: Double
    var proteinPer100g: Double
    var fatsPer100g: Double
    var calories: Double
    var carbs: Double
    var protein: Double
    var fats: Double
    var servingUnit: ServingUnit
    var unitWeight: Double

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

    init(from structured: StructuredFoodResult) {
        self.id = UUID()
        self.name = structured.name
        self.servingSize = structured.portionDescription
        self.servingGrams = structured.portionGrams
        self.caloriesPer100g = structured.caloriesPer100g
        self.carbsPer100g = structured.carbsPer100g
        self.proteinPer100g = structured.proteinPer100g
        self.fatsPer100g = structured.fatsPer100g
        self.calories = structured.calories
        self.carbs = structured.carbs
        self.protein = structured.protein
        self.fats = structured.fats
        self.servingUnit = ServingUnit(rawValue: structured.resolvedUnit) ?? .grams
        self.unitWeight = structured.resolvedUnitWeight
    }

    init(from food: FoodItem) {
        self.id = food.id
        self.name = food.name
        self.servingSize = food.servingSize
        self.servingGrams = food.servingGrams
        self.caloriesPer100g = food.caloriesPer100g
        self.carbsPer100g = food.carbsPer100g
        self.proteinPer100g = food.proteinPer100g
        self.fatsPer100g = food.fatsPer100g
        self.calories = food.calories
        self.carbs = food.carbs
        self.protein = food.protein
        self.fats = food.fats
        self.servingUnit = food.servingUnit
        self.unitWeight = food.unitWeight
    }

    init(from snapshot: FavoriteFoodSnapshot) {
        self.id = UUID()
        self.name = snapshot.name
        self.servingSize = snapshot.servingSize
        self.servingGrams = snapshot.servingGrams
        self.caloriesPer100g = snapshot.caloriesPer100g
        self.carbsPer100g = snapshot.carbsPer100g
        self.proteinPer100g = snapshot.proteinPer100g
        self.fatsPer100g = snapshot.fatsPer100g
        self.calories = snapshot.calories
        self.carbs = snapshot.carbs
        self.protein = snapshot.protein
        self.fats = snapshot.fats
        self.servingUnit = ServingUnit(rawValue: snapshot.servingUnit) ?? .grams
        self.unitWeight = snapshot.unitWeight
    }

    /// Recalculate macros based on current servingGrams using per-100g values
    mutating func recalculateFromGrams() {
        guard caloriesPer100g > 0 else { return }
        let factor = servingGrams / 100.0
        calories = caloriesPer100g * factor
        carbs = carbsPer100g * factor
        protein = proteinPer100g * factor
        fats = fatsPer100g * factor
    }

    func toFoodItem() -> FoodItem {
        FoodItem(
            name: name,
            servingSize: servingSize,
            servingGrams: servingGrams,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fats: fats,
            caloriesPer100g: caloriesPer100g,
            carbsPer100g: carbsPer100g,
            proteinPer100g: proteinPer100g,
            fatsPer100g: fatsPer100g,
            servingUnit: servingUnit,
            unitWeight: unitWeight
        )
    }
}
