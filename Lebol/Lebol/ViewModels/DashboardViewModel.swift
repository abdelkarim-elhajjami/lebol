import SwiftUI
import SwiftData

@MainActor @Observable
final class DashboardViewModel {
    var todayLog: DailyLog?
    var profile: UserProfile?
    var selectedDate = Date()
    var streak: Int = 0

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadData()
    }

    var caloriesLeft: Int {
        guard let profile else { return 0 }
        let target = Double(profile.dailyCalorieTarget)
        let eaten = todayLog?.totalCaloriesEaten ?? 0
        let burned = todayLog?.caloriesBurned ?? 0

        return Int(target + burned - eaten)
    }

    var caloriesEaten: Int {
        Int(todayLog?.totalCaloriesEaten ?? 0)
    }

    var caloriesBurned: Int {
        Int(todayLog?.caloriesBurned ?? 0)
    }

    var carbsEaten: Double { todayLog?.totalCarbsEaten ?? 0 }
    var proteinEaten: Double { todayLog?.totalProteinEaten ?? 0 }
    var fatsEaten: Double { todayLog?.totalFatsEaten ?? 0 }

    // Macro targets: body-weight-based protein, 25% fat, carbs as remainder
    // When burned calories are added, protein stays the same (weight-based), fat/carbs scale
    private var macroTargets: (carbs: Int, protein: Int, fats: Int) {
        guard let profile else { return (243, 152, 58) }
        let kcal = Double(profile.dailyCalorieTarget) + (todayLog?.caloriesBurned ?? 0)
        return NutritionCalculator.calculateMacros(dailyCalories: Int(kcal), weightKg: profile.weightKg)
    }

    var carbsTarget: Double { Double(macroTargets.carbs) }
    var proteinTarget: Double { Double(macroTargets.protein) }
    var fatsTarget: Double { Double(macroTargets.fats) }

    var calorieProgress: Double {
        guard let profile else { return 0 }
        let target = Double(profile.dailyCalorieTarget)
        let burned = todayLog?.caloriesBurned ?? 0
        let effectiveTarget = target + burned
        guard effectiveTarget > 0 else { return 0 }
        return (todayLog?.totalCaloriesEaten ?? 0) / effectiveTarget
    }

    var waterConsumed: Double { todayLog?.waterMl ?? 0 }
    var waterGoal: Double { Double(profile?.waterGoalMl ?? 3100) }
    // Glass size: 250 ml (matches add-water button amount)
    var waterGlasses: Int { Int(waterConsumed / 250) }
    var waterGlassesTarget: Int { Int(ceil(waterGoal / 250)) }

    func meals(for type: MealType) -> [MealEntry] {
        todayLog?.meals.filter { $0.mealType == type } ?? []
    }

    func calories(for type: MealType) -> Int {
        Int(meals(for: type).reduce(0) { $0 + $1.totalCalories })
    }

    func reloadData() {
        todayLog = DailyLog.fetchOrCreate(for: selectedDate, in: modelContext)

        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? modelContext.fetch(profileDescriptor) {
            profile = profiles.first
        }

        streak = DailyLog.currentStreak(in: modelContext)
    }

    func addWater(amount: Double) {
        guard let log = todayLog else { return }
        log.waterMl += amount
        modelContext.saveWithLogging()

        if let userId = profile?.supabaseUserId {
            let logRow = SupabaseDTOBuilder.dailyLogRow(from: log, userId: userId)
            Task { await SyncService.shared.pushDailyLogRow(logRow) }
        }
    }
}
