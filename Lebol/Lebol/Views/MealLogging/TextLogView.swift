import SwiftUI

struct TextLogView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var foodDescription = ""
    @State private var selectedMealType: MealType
    @State private var coordinator = MealAnalysisCoordinator()
    private let logDate: Date
    var onMealSaved: (() -> Void)?

    init(mealType: MealType = .lunch, logDate: Date = Date(), onMealSaved: (() -> Void)? = nil) {
        _selectedMealType = State(initialValue: mealType)
        self.logDate = logDate
        self.onMealSaved = onMealSaved
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Meal type picker
                HStack(spacing: 8) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Button {
                            selectedMealType = type
                        } label: {
                            Text(type.rawValue)
                                .font(LebolFont.caption())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(selectedMealType == type ? Color.lebolPrimary : Color.lebolDivider)
                                )
                                .foregroundColor(selectedMealType == type ? .white : .lebolTextPrimary)
                        }
                    }
                }

                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What did you eat?")
                        .font(LebolFont.headline())
                        .foregroundColor(.lebolTextPrimary)

                    TextEditor(text: $foodDescription)
                        .font(LebolFont.body())
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color.lebolSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.lebolBorder, lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            if foodDescription.isEmpty {
                                Text("e.g. chicken breast with rice and salad")
                                    .font(LebolFont.body())
                                    .foregroundColor(.lebolTextTertiary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Error
                if let error = coordinator.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.lebolWarning)
                        Text(error)
                            .font(LebolFont.caption())
                            .foregroundColor(.lebolError)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.lebolError.opacity(0.1))
                    )
                }

                Spacer()

                // Analyze button
                if coordinator.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.lebolPrimary)
                        Text("Analyzing...")
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)
                    }
                } else {
                    Button {
                        Task { await coordinator.analyzeText(foodDescription.trimmingCharacters(in: .whitespaces)) }
                    } label: {
                        Text("Analyze")
                    }
                    .buttonStyle(LebolPrimaryButtonStyle(isEnabled: !foodDescription.trimmingCharacters(in: .whitespaces).isEmpty))
                    .disabled(foodDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(20)
            .background(Color.lebolBackground)
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $coordinator.showingReview) {
                MealReviewView(
                    reviewItems: coordinator.reviewItems,
                    mealName: coordinator.reviewMealName,
                    mealType: selectedMealType,
                    logDate: logDate,
                    onSave: { onMealSaved?(); dismiss() }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}
