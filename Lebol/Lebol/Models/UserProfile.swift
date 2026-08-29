import Foundation
import SwiftData

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"

    var symbolName: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        }
    }
}

@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date
    var gender: Gender
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var startingWeightKg: Double
    var targetWeightKg: Double
    var weeklyGoalGrams: Int
    var dailyCalorieTarget: Int
    var dailyCarbsTarget: Int
    var dailyProteinTarget: Int
    var dailyFatsTarget: Int
    var waterGoalMl: Int
    var useMetric: Bool
    var supabaseUserId: String?
    var email: String?

    var isAuthenticated: Bool { supabaseUserId != nil }

    init(
        gender: Gender = .male,
        age: Int = 30,
        heightCm: Double = 170,
        weightKg: Double = 80,
        startingWeightKg: Double = 80,
        targetWeightKg: Double = 65,
        weeklyGoalGrams: Int = 800,
        dailyCalorieTarget: Int = 1620,
        dailyCarbsTarget: Int = 149,
        dailyProteinTarget: Int = 128,
        dailyFatsTarget: Int = 45,
        waterGoalMl: Int = 2600,
        useMetric: Bool = true
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.gender = gender
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.startingWeightKg = startingWeightKg
        self.targetWeightKg = targetWeightKg
        self.weeklyGoalGrams = weeklyGoalGrams
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyCarbsTarget = dailyCarbsTarget
        self.dailyProteinTarget = dailyProteinTarget
        self.dailyFatsTarget = dailyFatsTarget
        self.waterGoalMl = waterGoalMl
        self.useMetric = useMetric
    }

    /// Recalculate all derived targets (calories, macros, water) from current profile values.
    func recalculateTargets() {
        dailyCalorieTarget = NutritionCalculator.calculateDailyCalories(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            weeklyGoalGrams: weeklyGoalGrams
        )

        let macros = NutritionCalculator.calculateMacros(dailyCalories: dailyCalorieTarget, weightKg: weightKg)
        dailyCarbsTarget = macros.carbs
        dailyProteinTarget = macros.protein
        dailyFatsTarget = macros.fats

        waterGoalMl = NutritionCalculator.calculateWaterGoal(weightKg: weightKg)
    }
}
