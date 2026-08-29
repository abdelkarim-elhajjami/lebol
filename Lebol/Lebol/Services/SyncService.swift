import Foundation
import SwiftData
import Supabase

/// Bridges SwiftData local persistence with Supabase cloud storage.
/// All push methods accept Codable DTOs — never @Model objects — to avoid data races.
final class SyncService: Sendable {
    static let shared = SyncService()

    private var client: SupabaseClient? { AuthService.shared.client }

    private init() {}

    // MARK: - Pull (fetch all data from cloud)

    /// Pull all user data from Supabase and populate local SwiftData.
    /// Deletes existing local data first to avoid duplicates.
    @MainActor
    func pullAll(userId: String, modelContext: ModelContext) async throws -> Bool {
        guard let client else { return false }
        // Check if profile exists in cloud
        let profileRows: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        guard let remoteProfile = profileRows.first else {
            return false // No cloud data — new account
        }

        // Delete existing local data to avoid duplicates
        let existingProfiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        for p in existingProfiles { modelContext.delete(p) }
        let existingLogs = (try? modelContext.fetch(FetchDescriptor<DailyLog>())) ?? []
        for l in existingLogs { modelContext.delete(l) }
        let existingWeights = (try? modelContext.fetch(FetchDescriptor<WeightEntry>())) ?? []
        for w in existingWeights { modelContext.delete(w) }
        let existingFavs = (try? modelContext.fetch(FetchDescriptor<FavoriteMeal>())) ?? []
        for f in existingFavs { modelContext.delete(f) }

        // Create local UserProfile from cloud data
        let profile = UserProfile(
            gender: Gender(rawValue: remoteProfile.gender) ?? .male,
            age: remoteProfile.age,
            heightCm: remoteProfile.height_cm,
            weightKg: remoteProfile.weight_kg,
            startingWeightKg: remoteProfile.starting_weight_kg,
            targetWeightKg: remoteProfile.target_weight_kg,
            weeklyGoalGrams: remoteProfile.weekly_goal_grams,
            dailyCalorieTarget: remoteProfile.daily_calorie_target,
            dailyCarbsTarget: remoteProfile.daily_carbs_target,
            dailyProteinTarget: remoteProfile.daily_protein_target,
            dailyFatsTarget: remoteProfile.daily_fats_target,
            waterGoalMl: remoteProfile.water_goal_ml,
            useMetric: remoteProfile.use_metric
        )
        profile.supabaseUserId = userId
        profile.email = remoteProfile.email
        modelContext.insert(profile)

        // Pull weight entries
        let weightRows: [SupabaseWeightEntry] = try await client
            .from("weight_entries")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value

        for row in weightRows {
            let entry = WeightEntry(weightKg: row.weight_kg)
            entry.date = row.date
            modelContext.insert(entry)
        }

        // Pull daily logs with meals and foods
        let logRows: [SupabaseDailyLog] = try await client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value

        for logRow in logRows {
            let log = DailyLog(date: logRow.date)
            log.totalCaloriesEaten = logRow.total_calories_eaten
            log.totalCarbsEaten = logRow.total_carbs_eaten
            log.totalProteinEaten = logRow.total_protein_eaten
            log.totalFatsEaten = logRow.total_fats_eaten
            log.caloriesBurned = logRow.calories_burned
            log.waterMl = logRow.water_ml
            modelContext.insert(log)

            // Pull meals for this log
            let mealRows: [SupabaseMealEntry] = try await client
                .from("meal_entries")
                .select()
                .eq("daily_log_id", value: logRow.id.uuidString)
                .execute()
                .value

            for mealRow in mealRows {
                let meal = MealEntry(
                    mealType: MealType(rawValue: mealRow.meal_type) ?? .breakfast,
                    name: mealRow.name,
                    isFavorite: mealRow.is_favorite,
                    loggedAt: mealRow.logged_at
                )
                modelContext.insert(meal)

                // Pull foods for this meal
                let foodRows: [SupabaseFoodItem] = try await client
                    .from("food_items")
                    .select()
                    .eq("meal_entry_id", value: mealRow.id.uuidString)
                    .execute()
                    .value

                for foodRow in foodRows {
                    let food = FoodItem(
                        name: foodRow.name,
                        servingSize: foodRow.serving_size,
                        servingGrams: foodRow.serving_grams,
                        calories: foodRow.calories,
                        carbs: foodRow.carbs,
                        protein: foodRow.protein,
                        fats: foodRow.fats,
                        caloriesPer100g: foodRow.calories_per_100g,
                        carbsPer100g: foodRow.carbs_per_100g,
                        proteinPer100g: foodRow.protein_per_100g,
                        fatsPer100g: foodRow.fats_per_100g,
                        servingUnit: ServingUnit(rawValue: foodRow.serving_unit) ?? .grams,
                        unitWeight: foodRow.unit_weight
                    )
                    modelContext.insert(food)
                    meal.foods.append(food)
                }

                log.meals.append(meal)
            }
        }

        // Pull favorite meals
        let favRows: [SupabaseFavoriteMeal] = try await client
            .from("favorite_meals")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        for row in favRows {
            let fav = FavoriteMeal(name: row.name, foods: [])
            fav.foodsData = Data(row.foods_data.utf8)
            fav.foodCount = row.food_count
            modelContext.insert(fav)
        }

        modelContext.saveWithLogging()
        return true
    }

    // MARK: - Push (accept Codable DTOs, not @Model objects)

    func pushProfileRow(_ row: SupabaseProfile) async {
        guard let client else { return }
        do {
            try await client.from("profiles").upsert(row).execute()
        } catch {
            print("[SyncService] pushProfile failed: \(error)")
        }
    }

    func pushWeightEntryRow(_ row: SupabaseWeightEntry) async {
        guard let client else { return }
        do {
            try await client.from("weight_entries").upsert(row).execute()
        } catch {
            print("[SyncService] pushWeightEntry failed: \(error)")
        }
    }

    func pushDailyLogRow(_ row: SupabaseDailyLog) async {
        guard let client else { return }
        do {
            try await client.from("daily_logs").upsert(row).execute()
        } catch {
            print("[SyncService] pushDailyLog failed: \(error)")
        }
    }

    func pushMealEntryRow(_ row: SupabaseMealEntry, foodRows: [SupabaseFoodItem]) async {
        guard let client else { return }
        do {
            try await client.from("meal_entries").upsert(row).execute()
        } catch {
            print("[SyncService] pushMealEntry failed: \(error)")
        }

        for foodRow in foodRows {
            await pushFoodItemRow(foodRow)
        }
    }

    func pushFoodItemRow(_ row: SupabaseFoodItem) async {
        guard let client else { return }
        do {
            try await client.from("food_items").upsert(row).execute()
        } catch {
            print("[SyncService] pushFoodItem failed: \(error)")
        }
    }

    func pushFavoriteMealRow(_ row: SupabaseFavoriteMeal) async {
        guard let client else { return }
        do {
            try await client.from("favorite_meals").upsert(row).execute()
        } catch {
            print("[SyncService] pushFavoriteMeal failed: \(error)")
        }
    }

    func deleteMealEntry(id: UUID) async {
        guard let client else { return }
        do {
            try await client.from("meal_entries").delete().eq("id", value: id.uuidString).execute()
        } catch {
            print("[SyncService] deleteMealEntry failed: \(error)")
        }
    }

    func deleteFavoriteMeal(id: UUID) async {
        guard let client else { return }
        do {
            try await client.from("favorite_meals").delete().eq("id", value: id.uuidString).execute()
        } catch {
            print("[SyncService] deleteFavoriteMeal failed: \(error)")
        }
    }

    // MARK: - Push all local data (after first sign-in from onboarding)

    @MainActor
    func pushAllLocalData(userId: String, modelContext: ModelContext) async {
        // Push profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first {
            let row = SupabaseDTOBuilder.profileRow(from: profile, userId: userId)
            await pushProfileRow(row)
        }

        // Push weight entries
        let weightDescriptor = FetchDescriptor<WeightEntry>()
        if let entries = try? modelContext.fetch(weightDescriptor) {
            for entry in entries {
                let row = SupabaseDTOBuilder.weightEntryRow(from: entry, userId: userId)
                await pushWeightEntryRow(row)
            }
        }

        // Push daily logs with meals and foods
        let logDescriptor = FetchDescriptor<DailyLog>()
        if let logs = try? modelContext.fetch(logDescriptor) {
            for log in logs {
                let logRow = SupabaseDTOBuilder.dailyLogRow(from: log, userId: userId)
                await pushDailyLogRow(logRow)
                for meal in log.meals {
                    let (mealRow, foodRows) = SupabaseDTOBuilder.mealEntryRows(from: meal, dailyLogId: log.id, userId: userId)
                    await pushMealEntryRow(mealRow, foodRows: foodRows)
                }
            }
        }

        // Push favorite meals
        let favDescriptor = FetchDescriptor<FavoriteMeal>()
        if let favs = try? modelContext.fetch(favDescriptor) {
            for fav in favs {
                let row = SupabaseDTOBuilder.favoriteMealRow(from: fav, userId: userId)
                await pushFavoriteMealRow(row)
            }
        }
    }
}

// MARK: - DTO Builder (extracts Sendable DTOs from @Model objects on MainActor)

@MainActor
enum SupabaseDTOBuilder {
    static func profileRow(from profile: UserProfile, userId: String) -> SupabaseProfile {
        SupabaseProfile(
            id: profile.id,
            user_id: userId,
            created_at: profile.createdAt,
            gender: profile.gender.rawValue,
            age: profile.age,
            height_cm: profile.heightCm,
            weight_kg: profile.weightKg,
            starting_weight_kg: profile.startingWeightKg,
            target_weight_kg: profile.targetWeightKg,
            weekly_goal_grams: profile.weeklyGoalGrams,
            daily_calorie_target: profile.dailyCalorieTarget,
            daily_carbs_target: profile.dailyCarbsTarget,
            daily_protein_target: profile.dailyProteinTarget,
            daily_fats_target: profile.dailyFatsTarget,
            water_goal_ml: profile.waterGoalMl,
            use_metric: profile.useMetric,
            email: profile.email
        )
    }

    static func weightEntryRow(from entry: WeightEntry, userId: String) -> SupabaseWeightEntry {
        SupabaseWeightEntry(
            id: entry.id,
            user_id: userId,
            date: entry.date,
            weight_kg: entry.weightKg
        )
    }

    static func dailyLogRow(from log: DailyLog, userId: String) -> SupabaseDailyLog {
        SupabaseDailyLog(
            id: log.id,
            user_id: userId,
            date: log.date,
            total_calories_eaten: log.totalCaloriesEaten,
            total_carbs_eaten: log.totalCarbsEaten,
            total_protein_eaten: log.totalProteinEaten,
            total_fats_eaten: log.totalFatsEaten,
            calories_burned: log.caloriesBurned,
            steps: log.steps,
            water_ml: log.waterMl
        )
    }

    static func mealEntryRows(from meal: MealEntry, dailyLogId: UUID, userId: String) -> (SupabaseMealEntry, [SupabaseFoodItem]) {
        let mealRow = SupabaseMealEntry(
            id: meal.id,
            user_id: userId,
            daily_log_id: dailyLogId,
            meal_type: meal.mealType.rawValue,
            name: meal.name,
            logged_at: meal.loggedAt,
            is_favorite: meal.isFavorite,
            notes: meal.notes
        )
        let foodRows = meal.foods.map { food in
            SupabaseFoodItem(
                id: food.id,
                user_id: userId,
                meal_entry_id: meal.id,
                name: food.name,
                serving_size: food.servingSize,
                serving_grams: food.servingGrams,
                calories: food.calories,
                carbs: food.carbs,
                protein: food.protein,
                fats: food.fats,
                calories_per_100g: food.caloriesPer100g,
                carbs_per_100g: food.carbsPer100g,
                protein_per_100g: food.proteinPer100g,
                fats_per_100g: food.fatsPer100g,
                source: food.source,
                serving_unit: food.servingUnit.rawValue,
                unit_weight: food.unitWeight
            )
        }
        return (mealRow, foodRows)
    }

    static func foodItemRow(from food: FoodItem, mealEntryId: UUID, userId: String) -> SupabaseFoodItem {
        SupabaseFoodItem(
            id: food.id,
            user_id: userId,
            meal_entry_id: mealEntryId,
            name: food.name,
            serving_size: food.servingSize,
            serving_grams: food.servingGrams,
            calories: food.calories,
            carbs: food.carbs,
            protein: food.protein,
            fats: food.fats,
            calories_per_100g: food.caloriesPer100g,
            carbs_per_100g: food.carbsPer100g,
            protein_per_100g: food.proteinPer100g,
            fats_per_100g: food.fatsPer100g,
            source: food.source,
            serving_unit: food.servingUnit.rawValue,
            unit_weight: food.unitWeight
        )
    }

    static func favoriteMealRow(from fav: FavoriteMeal, userId: String) -> SupabaseFavoriteMeal {
        SupabaseFavoriteMeal(
            id: fav.id,
            user_id: userId,
            name: fav.name,
            foods_data: String(data: fav.foodsData, encoding: .utf8) ?? "[]",
            food_count: fav.foodCount,
            created_at: fav.createdAt
        )
    }
}

// MARK: - Supabase Row Types (Codable DTOs)

struct SupabaseProfile: Codable, Sendable {
    let id: UUID
    let user_id: String
    let created_at: Date
    let gender: String
    let age: Int
    let height_cm: Double
    let weight_kg: Double
    let starting_weight_kg: Double
    let target_weight_kg: Double
    let weekly_goal_grams: Int
    let daily_calorie_target: Int
    let daily_carbs_target: Int
    let daily_protein_target: Int
    let daily_fats_target: Int
    let water_goal_ml: Int
    let use_metric: Bool
    var email: String?
}

struct SupabaseDailyLog: Codable, Sendable {
    let id: UUID
    let user_id: String
    let date: Date
    let total_calories_eaten: Double
    let total_carbs_eaten: Double
    let total_protein_eaten: Double
    let total_fats_eaten: Double
    let calories_burned: Double
    let steps: Int
    let water_ml: Double
}

struct SupabaseMealEntry: Codable, Sendable {
    let id: UUID
    let user_id: String
    let daily_log_id: UUID
    let meal_type: String
    let name: String
    let logged_at: Date
    let is_favorite: Bool
    let notes: String?
}

struct SupabaseFoodItem: Codable, Sendable {
    let id: UUID
    let user_id: String
    let meal_entry_id: UUID
    let name: String
    let serving_size: String
    let serving_grams: Double
    let calories: Double
    let carbs: Double
    let protein: Double
    let fats: Double
    let calories_per_100g: Double
    let carbs_per_100g: Double
    let protein_per_100g: Double
    let fats_per_100g: Double
    let source: String
    let serving_unit: String
    let unit_weight: Double
}

struct SupabaseWeightEntry: Codable, Sendable {
    let id: UUID
    let user_id: String
    let date: Date
    let weight_kg: Double
}

struct SupabaseWaterEntry: Codable, Sendable {
    let id: UUID
    let user_id: String
    let date: Date
    let amount_ml: Double
}

struct SupabaseFavoriteMeal: Codable, Sendable {
    let id: UUID
    let user_id: String
    let name: String
    let foods_data: String
    let food_count: Int
    let created_at: Date
}
