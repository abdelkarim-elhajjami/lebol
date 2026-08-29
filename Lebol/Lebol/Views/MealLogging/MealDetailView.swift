import SwiftUI
import SwiftData

// MARK: - MealDetailView (Viewing Mode Only)

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let mealType: MealType
    private let logDate: Date

    @Binding private var meals: [MealEntry]
    private let dailyLog: DailyLog?

    @State private var showingFoodSearch = false
    @State private var showingAddSheet = false
    @State private var editingFood: FoodItem?
    @State private var activeMeal: MealEntry?
    @State private var mealToDelete: MealEntry?
    @State private var mealToDeleteName: String = ""

    // MARK: - Init

    init(mealType: MealType, meals: Binding<[MealEntry]>, dailyLog: DailyLog?, logDate: Date = Date()) {
        self.mealType = mealType
        self.logDate = logDate
        self._meals = meals
        self.dailyLog = dailyLog
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    MealCalorieCard(totalCalories: totalCalories)
                    MealMacroCards(carbs: totalCarbs, protein: totalProtein, fats: totalFats)

                    // Per-meal cards
                    ForEach(filteredMeals, id: \.id) { meal in
                        MealEntryCard(
                            meal: meal,
                            onToggleFavorite: { toggleFavoriteSingle(meal) },
                            onDelete: {
                                mealToDeleteName = meal.displayName
                                mealToDelete = meal
                            },
                            onEditFood: { food in
                                editingFood = food
                            },
                            onAddFood: {
                                activeMeal = meal
                                showingFoodSearch = true
                            }
                        )
                    }

                    logAnotherMealButton
                }
                .padding(16)
            }
            .background(Color.lebolBackground)
            .lebolDismissToolbar(placement: .confirmationAction)
        }
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView { selectedFood in
                if let meal = activeMeal, !meal.isDeleted {
                    DataService.addFoodToMeal(selectedFood, meal: meal, dailyLog: dailyLog, in: modelContext)
                }
                showingFoodSearch = false
                activeMeal = nil
            }
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: {
            dailyLog?.recalculateTotals()
        }) {
            AddActionSheet(fixedMealType: mealType, logDate: logDate)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.lebolBackground)
        }
        .sheet(item: $editingFood) { food in
            if !food.isDeleted {
                PortionEditorView(food: food) { updatedFood in
                    dailyLog?.recalculateTotals()
                    modelContext.saveWithLogging()
                }
            }
        }
        .confirmationDialog(
            "Delete this meal?",
            isPresented: Binding(
                get: { mealToDelete != nil },
                set: { if !$0 { mealToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    deleteSingleMeal(meal)
                }
                mealToDelete = nil
            }
        } message: {
            Text("Remove \"\(mealToDeleteName)\" and all its ingredients?")
        }
    }

    // MARK: - Data Accessors

    private var filteredMeals: [MealEntry] {
        meals.filter { $0.mealType == mealType }
    }

    private var displayDate: String {
        if let first = filteredMeals.first {
            if Calendar.current.isDateInToday(first.loggedAt) {
                return "\(mealType.rawValue), Today"
            }
            return "\(mealType.rawValue), \(first.loggedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return mealType.rawValue
    }

    private var totalCalories: Double {
        filteredMeals.reduce(0) { $0 + $1.totalCalories }
    }

    private var totalCarbs: Double {
        filteredMeals.reduce(0) { $0 + $1.totalCarbs }
    }

    private var totalProtein: Double {
        filteredMeals.reduce(0) { $0 + $1.totalProtein }
    }

    private var totalFats: Double {
        filteredMeals.reduce(0) { $0 + $1.totalFats }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mealType.rawValue)
                .font(LebolFont.title2())
                .foregroundColor(.lebolTextPrimary)

            Text(displayDate)
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Log Another Meal

    private var logAnotherMealButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Log Another Meal")
                    .font(LebolFont.body())
            }
            .foregroundColor(.lebolPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lebolPrimary.opacity(0.3), lineWidth: 1.5)
            )
        }
    }

    // MARK: - Actions

    private func toggleFavoriteSingle(_ meal: MealEntry) {
        meal.isFavorite.toggle()
        Haptics.light()
        modelContext.saveWithLogging()

        if meal.isFavorite {
            let items = meal.foods.map { ReviewableFoodItem(from: $0) }
            DataService.saveFavorite(name: meal.displayName, items: items, in: modelContext)
        } else {
            DataService.deleteFavoriteMatching(foods: meal.foods, in: modelContext)
        }
    }

    private func deleteSingleMeal(_ meal: MealEntry) {
        guard !meal.isDeleted else { return }
        Haptics.error()
        let wasLastMeal = filteredMeals.count == 1
        DataService.deleteMeal(meal, from: dailyLog, in: modelContext)
        if wasLastMeal {
            dismiss()
        }
    }
}
