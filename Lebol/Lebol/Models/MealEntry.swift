import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var symbolName: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "fork.knife"
        case .dinner: return "moon.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
}

@Model
final class MealEntry {
    var id: UUID
    var mealType: MealType
    var name: String
    var loggedAt: Date
    @Relationship(deleteRule: .cascade) var foods: [FoodItem]
    var isFavorite: Bool
    // TODO: Remove in next schema migration
    var notes: String?

    var displayName: String {
        name.isEmpty ? foods.first?.name ?? mealType.rawValue : name
    }

    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }

    var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.carbs }
    }

    var totalProtein: Double {
        foods.reduce(0) { $0 + $1.protein }
    }

    var totalFats: Double {
        foods.reduce(0) { $0 + $1.fats }
    }

    init(mealType: MealType, name: String = "", isFavorite: Bool = false, loggedAt: Date = Date()) {
        self.id = UUID()
        self.mealType = mealType
        self.name = name
        self.loggedAt = loggedAt
        self.foods = []
        self.isFavorite = isFavorite
    }
}
