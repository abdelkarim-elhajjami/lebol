import Foundation
import SwiftData

// MARK: - Codable snapshot of food items for favorite storage

struct FavoriteFoodSnapshot: Codable {
    let name: String
    let servingSize: String
    let servingGrams: Double
    let calories: Double
    let carbs: Double
    let protein: Double
    let fats: Double
    let caloriesPer100g: Double
    let carbsPer100g: Double
    let proteinPer100g: Double
    let fatsPer100g: Double
    let servingUnit: String
    let unitWeight: Double

    init(from item: ReviewableFoodItem) {
        self.name = item.name
        self.servingSize = item.servingSize
        self.servingGrams = item.servingGrams
        self.calories = item.calories
        self.carbs = item.carbs
        self.protein = item.protein
        self.fats = item.fats
        self.caloriesPer100g = item.caloriesPer100g
        self.carbsPer100g = item.carbsPer100g
        self.proteinPer100g = item.proteinPer100g
        self.fatsPer100g = item.fatsPer100g
        self.servingUnit = item.servingUnit.rawValue
        self.unitWeight = item.unitWeight
    }

    func toReviewableItem() -> ReviewableFoodItem {
        ReviewableFoodItem(from: self)
    }
}

// MARK: - FavoriteMeal (independent template, decoupled from logged meals)

@Model
final class FavoriteMeal {
    var id: UUID
    var name: String
    var foodsData: Data
    var totalCalories: Double
    var foodCount: Int
    var createdAt: Date

    init(name: String, foods: [ReviewableFoodItem]) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.totalCalories = foods.reduce(0) { $0 + $1.calories }
        self.foodCount = foods.count

        let snapshots = foods.map { FavoriteFoodSnapshot(from: $0) }
        self.foodsData = (try? JSONEncoder().encode(snapshots)) ?? Data()
    }

    func toReviewableItems() -> [ReviewableFoodItem] {
        guard let snapshots = try? JSONDecoder().decode([FavoriteFoodSnapshot].self, from: foodsData) else {
            return []
        }
        return snapshots.map { $0.toReviewableItem() }
    }
}
