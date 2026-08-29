import Foundation
import SwiftData

@MainActor
enum DataService {

    // MARK: - Auth helper

    private static func authenticatedUserId(in context: ModelContext) -> String? {
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? context.fetch(descriptor))?.first?.supabaseUserId
    }

    /// Create a MealEntry from reviewed food items, append to the DailyLog for the given date, and save.
    static func saveMeal(
        items: [ReviewableFoodItem],
        name: String,
        type: MealType,
        isFavorite: Bool,
        for date: Date = Date(),
        in context: ModelContext
    ) {
        let meal = MealEntry(mealType: type, name: name, isFavorite: isFavorite, loggedAt: date)

        for item in items {
            let food = item.toFoodItem()
            context.insert(food)
            meal.foods.append(food)
        }

        context.insert(meal)

        let log = DailyLog.fetchOrCreate(for: date, in: context)
        log.meals.append(meal)
        log.recalculateTotals()
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let logRow = SupabaseDTOBuilder.dailyLogRow(from: log, userId: userId)
            let (mealRow, foodRows) = SupabaseDTOBuilder.mealEntryRows(from: meal, dailyLogId: log.id, userId: userId)
            Task {
                await SyncService.shared.pushDailyLogRow(logRow)
                await SyncService.shared.pushMealEntryRow(mealRow, foodRows: foodRows)
            }
        }
    }

    /// Add a single food item to an existing meal.
    static func addFoodToMeal(
        _ reviewable: ReviewableFoodItem,
        meal: MealEntry,
        dailyLog: DailyLog?,
        in context: ModelContext
    ) {
        let food = reviewable.toFoodItem()
        context.insert(food)
        meal.foods.append(food)
        dailyLog?.recalculateTotals()
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let foodRow = SupabaseDTOBuilder.foodItemRow(from: food, mealEntryId: meal.id, userId: userId)
            let logRow = dailyLog.map { SupabaseDTOBuilder.dailyLogRow(from: $0, userId: userId) }
            Task {
                await SyncService.shared.pushFoodItemRow(foodRow)
                if let logRow {
                    await SyncService.shared.pushDailyLogRow(logRow)
                }
            }
        }
    }

    /// Delete meals from a daily log.
    static func deleteMeals(
        _ meals: [MealEntry],
        from log: DailyLog?,
        in context: ModelContext
    ) {
        let mealIds = meals.map(\.id)
        for meal in meals {
            log?.meals.removeAll { $0.id == meal.id }
            context.delete(meal)
        }
        log?.recalculateTotals()
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let logRow = log.map { SupabaseDTOBuilder.dailyLogRow(from: $0, userId: userId) }
            Task {
                for id in mealIds {
                    await SyncService.shared.deleteMealEntry(id: id)
                }
                if let logRow {
                    await SyncService.shared.pushDailyLogRow(logRow)
                }
            }
        }
    }

    /// Delete a single meal from a daily log.
    static func deleteMeal(
        _ meal: MealEntry,
        from log: DailyLog?,
        in context: ModelContext
    ) {
        let mealId = meal.id
        log?.meals.removeAll { $0.id == meal.id }
        context.delete(meal)
        log?.recalculateTotals()
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let logRow = log.map { SupabaseDTOBuilder.dailyLogRow(from: $0, userId: userId) }
            Task {
                await SyncService.shared.deleteMealEntry(id: mealId)
                if let logRow {
                    await SyncService.shared.pushDailyLogRow(logRow)
                }
            }
        }
    }

    /// Toggle favorite status on meals.
    static func toggleFavorite(
        _ meals: [MealEntry],
        to value: Bool,
        in context: ModelContext
    ) {
        for meal in meals {
            meal.isFavorite = value
        }
        context.saveWithLogging()
    }

    // MARK: - Favorites

    /// Save a favorite meal template (skips if a favorite with the same name already exists).
    static func saveFavorite(name: String, items: [ReviewableFoodItem], in context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteMeal>()
        if let existing = try? context.fetch(descriptor),
           existing.contains(where: { $0.name == name }) {
            return
        }

        let favorite = FavoriteMeal(name: name, foods: items)
        context.insert(favorite)
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let row = SupabaseDTOBuilder.favoriteMealRow(from: favorite, userId: userId)
            Task { await SyncService.shared.pushFavoriteMealRow(row) }
        }
    }

    /// Delete a favorite meal template.
    static func deleteFavorite(_ favorite: FavoriteMeal, in context: ModelContext) {
        let favId = favorite.id
        context.delete(favorite)
        context.saveWithLogging()

        if authenticatedUserId(in: context) != nil {
            Task { await SyncService.shared.deleteFavoriteMeal(id: favId) }
        }
    }

    /// Delete a favorite meal matching the given foods by name-based key.
    static func deleteFavoriteMatching(foods: [FoodItem], in context: ModelContext) {
        let foodKey = foods.map { $0.name.lowercased() }.sorted().joined(separator: "+")
        let descriptor = FetchDescriptor<FavoriteMeal>()
        guard let favorites = try? context.fetch(descriptor) else { return }
        if let match = favorites.first(where: {
            let key = $0.toReviewableItems().map { $0.name.lowercased() }.sorted().joined(separator: "+")
            return key == foodKey
        }) {
            deleteFavorite(match, in: context)
        }
    }

    /// Rename a favorite meal template.
    static func renameFavorite(_ favorite: FavoriteMeal, to newName: String, in context: ModelContext) {
        favorite.name = newName
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let row = SupabaseDTOBuilder.favoriteMealRow(from: favorite, userId: userId)
            Task { await SyncService.shared.pushFavoriteMealRow(row) }
        }
    }

    /// Update a favorite meal template with new name and items.
    static func updateFavorite(_ favorite: FavoriteMeal, name: String, items: [ReviewableFoodItem], in context: ModelContext) {
        favorite.name = name
        favorite.totalCalories = items.reduce(0) { $0 + $1.calories }
        favorite.foodCount = items.count
        let snapshots = items.map { FavoriteFoodSnapshot(from: $0) }
        favorite.foodsData = (try? JSONEncoder().encode(snapshots)) ?? Data()
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let row = SupabaseDTOBuilder.favoriteMealRow(from: favorite, userId: userId)
            Task { await SyncService.shared.pushFavoriteMealRow(row) }
        }
    }

    /// Log burned calories from an activity.
    static func logActivity(burned: Double, in context: ModelContext) {
        let log = DailyLog.fetchOrCreate(in: context)
        log.caloriesBurned += burned
        context.saveWithLogging()

        if let userId = authenticatedUserId(in: context) {
            let logRow = SupabaseDTOBuilder.dailyLogRow(from: log, userId: userId)
            Task { await SyncService.shared.pushDailyLogRow(logRow) }
        }
    }

    /// Log a new weight entry and update the user profile.
    static func logWeight(_ kg: Double, profile: UserProfile, in context: ModelContext) {
        let entry = WeightEntry(weightKg: kg)
        context.insert(entry)
        profile.weightKg = kg
        profile.recalculateTargets()
        context.saveWithLogging()

        if let userId = profile.supabaseUserId {
            let weightRow = SupabaseDTOBuilder.weightEntryRow(from: entry, userId: userId)
            let profileRow = SupabaseDTOBuilder.profileRow(from: profile, userId: userId)
            Task {
                await SyncService.shared.pushWeightEntryRow(weightRow)
                await SyncService.shared.pushProfileRow(profileRow)
            }
        }
    }
}
