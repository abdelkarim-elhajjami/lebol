import Foundation
import SwiftData

// MARK: - Schema Migration Plan

enum LebolMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LebolSchemaV1.self, LebolSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: LebolSchemaV1.self,
        toVersion: LebolSchemaV2.self
    )
}

// MARK: - V1

enum LebolSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            DailyLog.self,
            MealEntry.self,
            FoodItem.self,
            WeightEntry.self,
            WaterEntry.self,
            SupportMessage.self
        ]
    }
}

// MARK: - V2 (adds FavoriteMeal)

enum LebolSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            DailyLog.self,
            MealEntry.self,
            FoodItem.self,
            WeightEntry.self,
            WaterEntry.self,
            SupportMessage.self,
            FavoriteMeal.self
        ]
    }
}

