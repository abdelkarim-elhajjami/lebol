import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var totalCaloriesEaten: Double
    var totalCarbsEaten: Double
    var totalProteinEaten: Double
    var totalFatsEaten: Double
    var caloriesBurned: Double
    // Unused — kept for SwiftData schema compatibility (removing columns requires custom migration)
    var steps: Int
    var waterMl: Double
    @Relationship(deleteRule: .cascade) var meals: [MealEntry]

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.totalCaloriesEaten = 0
        self.totalCarbsEaten = 0
        self.totalProteinEaten = 0
        self.totalFatsEaten = 0
        self.caloriesBurned = 0
        self.steps = 0
        self.waterMl = 0
        self.meals = []
    }

    func recalculateTotals() {
        totalCaloriesEaten = meals.reduce(0) { $0 + $1.totalCalories }
        totalCarbsEaten = meals.reduce(0) { $0 + $1.totalCarbs }
        totalProteinEaten = meals.reduce(0) { $0 + $1.totalProtein }
        totalFatsEaten = meals.reduce(0) { $0 + $1.totalFats }
    }

    // MARK: - Shared Utilities

    /// Fetch today's DailyLog or create one if it doesn't exist.
    static func fetchOrCreate(for date: Date = Date(), in context: ModelContext) -> DailyLog {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<DailyLog> { log in
            log.date == startOfDay
        }
        let descriptor = FetchDescriptor<DailyLog>(predicate: predicate)

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let newLog = DailyLog(date: startOfDay)
        context.insert(newLog)
        context.saveWithLogging()
        return newLog
    }

    /// Calculate the current logging streak (consecutive days with at least one meal).
    static func currentStreak(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 365
        guard let logs = try? context.fetch(descriptor) else { return 0 }

        let calendar = Calendar.current
        var count = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Build a set of day-starts for O(1) lookup
        let logDates = Set(logs.compactMap { log -> Date? in
            guard !log.meals.isEmpty else { return nil }
            return calendar.startOfDay(for: log.date)
        })

        for _ in 0..<365 {
            guard logDates.contains(checkDate) else { break }
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return count
    }
}
