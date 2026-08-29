import SwiftUI

// MARK: - Shared UI Components for MealDetailView & MealReviewView

/// Wrapper to make an Int index usable with `.sheet(item:)`
struct IdentifiableIndex: Identifiable {
    let id = UUID()
    let value: Int
}

struct MealActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(LebolFont.subheadline())
            }
            .foregroundColor(.lebolTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.lebolSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct MealCalorieCard: View {
    let totalCalories: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories and nutrients")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)

            HStack(spacing: 8) {
                MacroIcon.calories(size: 24)
                Text("\(Int(totalCalories))")
                    .font(LebolFont.metricSmall())
                    .foregroundColor(.lebolTextPrimary)
                Text("calories")
                    .font(LebolFont.body())
                    .foregroundColor(.lebolTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.lebolSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(16)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MealMacroCards: View {
    let carbs: Double
    let protein: Double
    let fats: Double

    var body: some View {
        HStack(spacing: 8) {
            macroCard(label: "Carbs", icon: MacroIcon.carbs(), value: carbs, color: .lebolCarbs)
            macroCard(label: "Protein", icon: MacroIcon.protein(), value: protein, color: .lebolProtein)
            macroCard(label: "Fat", icon: MacroIcon.fats(), value: fats, color: .lebolFats)
        }
    }

    private func macroCard(label: String, icon: some View, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextSecondary)
                Spacer()
                icon
            }
            Text(String(format: "%.1f g", value))
                .font(LebolFont.headline())
                .foregroundColor(.lebolTextPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lebolBorder, lineWidth: 1)
        )
    }
}

// MARK: - MealEntryCard (per-meal card within MealDetailView)

struct MealEntryCard: View {
    let meal: MealEntry
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    let onEditFood: (FoodItem) -> Void
    let onAddFood: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Meal header: name, calories, action buttons
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.displayName)
                        .font(LebolFont.headline())
                        .foregroundColor(.lebolTextPrimary)
                        .lineLimit(1)
                    Text("\(Int(meal.totalCalories)) cal · \(meal.foods.count) item\(meal.foods.count == 1 ? "" : "s")")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: meal.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(meal.isFavorite ? .orange : .lebolTextSecondary)
                    }

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.lebolTextSecondary)
                    }
                }
            }

            // Ingredients for this meal only
            ForEach(meal.foods, id: \.id) { food in
                Button {
                    onEditFood(food)
                } label: {
                    IngredientRow(
                        name: food.name,
                        calories: Int(food.calories),
                        quantity: food.displayQuantity,
                        unit: food.displayUnitLabel
                    )
                }
                .buttonStyle(.plain)
            }

            // Per-meal "Add More" button
            Button {
                onAddFood()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add More")
                        .font(LebolFont.caption())
                }
                .foregroundColor(.lebolPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct IngredientRow: View {
    let name: String
    let calories: Int
    let quantity: Double
    let unit: String

    var body: some View {
        let quantityLabel: String = {
            if unit == "pcs" {
                let formatted = quantity.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(quantity))" : String(format: "%.1f", quantity)
                return "\(formatted) pcs"
            }
            return "\(Int(quantity)) \(unit)"
        }()

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(LebolFont.body())
                    .foregroundColor(.lebolTextPrimary)
                Text("\(calories) cal")
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextSecondary)
            }

            Spacer()

            Text(quantityLabel)
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
        }
        .padding(12)
        .background(Color.lebolSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
