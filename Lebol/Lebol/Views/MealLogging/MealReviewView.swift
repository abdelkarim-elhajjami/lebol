import SwiftUI
import SwiftData

// MARK: - ReviewMode

enum ReviewMode {
    case logMeal(mealType: MealType, logDate: Date, onSave: () -> Void)
    case editFavorite(FavoriteMeal)
}

// MARK: - MealReviewView (Review & Save new meals from AI analysis, or edit favorites)

struct MealReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let mode: ReviewMode

    @State private var reviewItems: [ReviewableFoodItem]
    @State private var reviewMealName: String
    @State private var selectedMealType: MealType
    @State private var showingFoodSearch = false
    @State private var editingItemIndex: IdentifiableIndex?
    @State private var isFavorited = false
    @State private var isEditingName = false

    private var isEditFavoriteMode: Bool {
        if case .editFavorite = mode { return true }
        return false
    }

    // MARK: - Init (Log Meal)

    init(reviewItems: [ReviewableFoodItem], mealName: String, mealType: MealType, logDate: Date = Date(), onSave: @escaping () -> Void) {
        self.mode = .logMeal(mealType: mealType, logDate: logDate, onSave: onSave)
        self._selectedMealType = State(initialValue: mealType)
        self._reviewItems = State(initialValue: reviewItems)
        self._reviewMealName = State(initialValue: mealName)
    }

    // MARK: - Init (Edit Favorite)

    init(favorite: FavoriteMeal) {
        self.mode = .editFavorite(favorite)
        self._selectedMealType = State(initialValue: .breakfast)
        self._reviewItems = State(initialValue: favorite.toReviewableItems())
        self._reviewMealName = State(initialValue: favorite.name)
        self._isFavorited = State(initialValue: true)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    actionButtonsSection
                    MealCalorieCard(totalCalories: totalCalories)
                    MealMacroCards(carbs: totalCarbs, protein: totalProtein, fats: totalFats)
                    ingredientsSection

                    saveButton
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Color.lebolBackground)
            .lebolDismissToolbar(placement: .confirmationAction)
        }
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView { selectedFood in
                reviewItems.append(selectedFood)
                showingFoodSearch = false
            }
        }
        .sheet(item: $editingItemIndex) { item in
            if item.value < reviewItems.count {
                PortionEditorView(item: $reviewItems[item.value])
            }
        }
    }

    // MARK: - Data Accessors

    private var displayMealName: String {
        reviewMealName.isEmpty ? selectedMealType.rawValue : reviewMealName
    }

    private var displayDate: String {
        if isEditFavoriteMode {
            return "Favorite meal template"
        }
        if case .logMeal(_, let logDate, _) = mode {
            if Calendar.current.isDateInToday(logDate) {
                return "\(selectedMealType.rawValue), Today"
            }
            return "\(selectedMealType.rawValue), \(logDate.formatted(date: .abbreviated, time: .omitted))"
        }
        return ""
    }

    private var totalCalories: Double {
        reviewItems.reduce(0) { $0 + $1.calories }
    }

    private var totalCarbs: Double {
        reviewItems.reduce(0) { $0 + $1.carbs }
    }

    private var totalProtein: Double {
        reviewItems.reduce(0) { $0 + $1.protein }
    }

    private var totalFats: Double {
        reviewItems.reduce(0) { $0 + $1.fats }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditingName {
                TextField("Meal name", text: $reviewMealName)
                    .font(LebolFont.title2())
                    .foregroundColor(.lebolTextPrimary)
                    .onSubmit { isEditingName = false }
            } else {
                HStack {
                    Text(displayMealName)
                        .font(LebolFont.title2())
                        .foregroundColor(.lebolTextPrimary)
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.lebolTextSecondary)
                }
                .onTapGesture {
                    isEditingName = true
                }
            }

            Text(displayDate)
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
        }
        .padding(16)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            if !isEditFavoriteMode {
                MealActionButton(icon: isFavorited ? "star.fill" : "star", title: "Favorites") {
                    toggleFavorite()
                }
            }

            MealActionButton(icon: "trash", title: isEditFavoriteMode ? "Discard" : "Delete") {
                Haptics.error()
                reviewItems.removeAll()
                dismiss()
            }
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                Spacer()
                Button {
                    showingFoodSearch = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add More")
                            .font(LebolFont.subheadline())
                    }
                    .foregroundColor(.lebolPrimary)
                }
            }

            ForEach(Array(reviewItems.enumerated()), id: \.element.id) { index, item in
                Button {
                    editingItemIndex = IdentifiableIndex(value: index)
                } label: {
                    IngredientRow(
                        name: item.name,
                        calories: Int(item.calories),
                        quantity: item.displayQuantity,
                        unit: item.displayUnitLabel
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        Haptics.light()
                        reviewItems.remove(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(16)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveReviewedMeal()
        } label: {
            Text(isEditFavoriteMode ? "Save changes" : "Log this meal")
        }
        .buttonStyle(LebolPrimaryButtonStyle(isEnabled: !reviewItems.isEmpty))
        .disabled(reviewItems.isEmpty)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func saveReviewedMeal() {
        Haptics.success()

        switch mode {
        case .logMeal(_, let logDate, let onSave):
            DataService.saveMeal(
                items: reviewItems,
                name: reviewMealName,
                type: selectedMealType,
                isFavorite: isFavorited,
                for: logDate,
                in: modelContext
            )

            if isFavorited {
                DataService.saveFavorite(
                    name: reviewMealName,
                    items: reviewItems,
                    in: modelContext
                )
            }

            onSave()

        case .editFavorite(let favorite):
            DataService.updateFavorite(
                favorite,
                name: reviewMealName,
                items: reviewItems,
                in: modelContext
            )
        }

        dismiss()
    }

    private func toggleFavorite() {
        isFavorited.toggle()
        Haptics.light()
        // In reviewing mode, isFavorited state is applied when saving the meal
    }
}
