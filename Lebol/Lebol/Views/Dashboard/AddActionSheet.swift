import SwiftUI

struct AddActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMealType: MealType
    @State private var showingTextLog = false
    @State private var showingScanFood = false
    @State private var showingVoiceLog = false
    @State private var showingActivityLog = false
    @State private var showingFavorites = false
    @State private var favoriteReviewData: FavoriteReviewData?
    @State private var pendingFavoriteData: FavoriteReviewData?
    @State private var shouldDismissAfterSave = false

    private let fixedMealType: MealType?
    private let logDate: Date

    init(fixedMealType: MealType? = nil, logDate: Date = Date()) {
        self.fixedMealType = fixedMealType
        self.logDate = logDate
        _selectedMealType = State(initialValue: fixedMealType ?? Self.suggestedMealType())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(fixedMealType?.rawValue ?? "Nutrition")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)

                    if fixedMealType == nil {
                        // Meal type selector
                        HStack(spacing: 8) {
                            ForEach(MealType.allCases) { type in
                                Button {
                                    Haptics.selection()
                                    selectedMealType = type
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.symbolName)
                                            .font(.system(size: 12))
                                        Text(type.rawValue)
                                            .font(LebolFont.caption())
                                    }
                                    .foregroundColor(selectedMealType == type ? .white : .lebolTextSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedMealType == type ? Color.lebolPrimary : Color.lebolSurface)
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ActionButton(icon: "star.fill", iconColor: .orange, title: "Favorites") {
                            showingFavorites = true
                        }

                        ActionButton(icon: "mic.fill", iconColor: .lebolSuccess, title: "Voice Log") {
                            showingVoiceLog = true
                        }

                        ActionButton(icon: "pencil", iconColor: .purple, title: "Create Meal") {
                            showingTextLog = true
                        }

                        ActionButton(icon: "camera.fill", iconColor: .lebolPrimary, title: "Scan Food") {
                            showingScanFood = true
                        }
                    }
                }

                if fixedMealType == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ActionButton(icon: "figure.run", iconColor: .orange, title: "Activity") {
                                showingActivityLog = true
                            }
                        }
                    }
                }

            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showingTextLog, onDismiss: dismissIfSaved) {
            TextLogView(mealType: selectedMealType, logDate: logDate, onMealSaved: { shouldDismissAfterSave = true })
        }
        .sheet(isPresented: $showingScanFood, onDismiss: dismissIfSaved) {
            FoodScanView(mealType: selectedMealType, logDate: logDate, onMealSaved: { shouldDismissAfterSave = true })
        }
        .sheet(isPresented: $showingVoiceLog, onDismiss: dismissIfSaved) {
            VoiceLogView(mealType: selectedMealType, logDate: logDate, onMealSaved: { shouldDismissAfterSave = true })
        }
        .sheet(isPresented: $showingActivityLog) {
            ActivityLogView()
        }
        .sheet(isPresented: $showingFavorites, onDismiss: {
            if let pending = pendingFavoriteData {
                favoriteReviewData = pending
                pendingFavoriteData = nil
            }
        }) {
            FavoritesView { items, name in
                pendingFavoriteData = FavoriteReviewData(items: items, name: name)
                showingFavorites = false
            }
        }
        .fullScreenCover(item: $favoriteReviewData, onDismiss: dismissIfSaved) { data in
            MealReviewView(
                reviewItems: data.items,
                mealName: data.name,
                mealType: selectedMealType,
                logDate: logDate,
                onSave: { shouldDismissAfterSave = true }
            )
        }
    }

    private func dismissIfSaved() {
        if shouldDismissAfterSave {
            dismiss()
        }
    }

    private static func suggestedMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 17..<22: return .dinner
        case 15..<17: return .snack
        default: return .snack
        }
    }
}

struct FavoriteReviewData: Identifiable {
    let id = UUID()
    let items: [ReviewableFoodItem]
    let name: String
}

struct ActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.lebolSurface)
            )
        }
        .buttonStyle(.plain)
    }
}
