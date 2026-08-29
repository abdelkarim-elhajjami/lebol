import SwiftUI

// MARK: - Height Editor (full-screen, matches HeightStepView)

struct ProfileHeightEditor: View {
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var heightCm: Double
    @State private var useMetric: Bool

    init(initialValue: Double, initialUseMetric: Bool = true, onSave: @escaping (Double) -> Void) {
        self.onSave = onSave
        _heightCm = State(initialValue: initialValue)
        _useMetric = State(initialValue: initialUseMetric)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("What's your height?")
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text("Your height helps shape your body proportions")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()

                HeightPicker(heightCm: $heightCm, useMetric: $useMetric, showMeasurementSystemToggle: false)

                Spacer()

                Button {
                    onSave(heightCm)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
        }
    }
}

// MARK: - Weight Editor (full-screen, matches WeightStepView)

struct ProfileWeightEditor: View {
    let title: String
    let subtitle: String
    let minValue: Double
    let maxValue: Double
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var weightKg: Double
    @State private var useMetric: Bool

    init(title: String, subtitle: String, initialValue: Double, minValue: Double = 40, maxValue: Double = 200, initialUseMetric: Bool = true, onSave: @escaping (Double) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.minValue = minValue
        self.maxValue = maxValue
        self.onSave = onSave
        _weightKg = State(initialValue: initialValue)
        _useMetric = State(initialValue: initialUseMetric)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text(title)
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text(subtitle)
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .padding(.top, 8)

                Spacer().frame(height: 24)

                WeightPicker(weightKg: $weightKg, useMetric: $useMetric, minValue: minValue, maxValue: maxValue, showMeasurementSystemToggle: false)

                Spacer()

                Button {
                    onSave(weightKg)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
        }
    }
}

// MARK: - Target Weight Editor (full-screen, uses TargetWeightPicker with warning zone + current weight ref)

struct ProfileTargetWeightEditor: View {
    let currentWeightKg: Double
    let heightCm: Double
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var targetWeightKg: Double
    @State private var useMetric: Bool

    init(initialValue: Double, currentWeightKg: Double, heightCm: Double, initialUseMetric: Bool = true, onSave: @escaping (Double) -> Void) {
        self.currentWeightKg = currentWeightKg
        self.heightCm = heightCm
        self.onSave = onSave
        _targetWeightKg = State(initialValue: initialValue)
        _useMetric = State(initialValue: initialUseMetric)
    }

    private var isTargetValid: Bool {
        NutritionCalculator.isTargetWeightValid(targetKg: targetWeightKg, currentKg: currentWeightKg, heightCm: heightCm).valid
    }

    private var validationReason: String? {
        let result = NutritionCalculator.isTargetWeightValid(targetKg: targetWeightKg, currentKg: currentWeightKg, heightCm: heightCm)
        return result.valid ? nil : result.reason
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("Goal weight")
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text("What are you aiming for?")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .padding(.top, 8)

                TargetWeightPicker(
                    targetWeightKg: $targetWeightKg,
                    useMetric: $useMetric,
                    currentWeightKg: currentWeightKg,
                    showMeasurementSystemToggle: false
                )

                // Healthy target card
                HealthyTargetInfoCard(heightCm: heightCm, useMetric: useMetric)

                if let reason = validationReason {
                    Text(reason)
                        .font(LebolFont.footnote())
                        .foregroundColor(.lebolError)
                        .padding(.top, 8)
                }

                Button {
                    onSave(targetWeightKg)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .disabled(!isTargetValid)
                .opacity(isTargetValid ? 1 : 0.5)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
        }
    }
}

// MARK: - Age Editor (full-screen, matches AgeStepView)

struct ProfileAgeEditor: View {
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var age: Int

    init(initialValue: Int, onSave: @escaping (Int) -> Void) {
        self.onSave = onSave
        _age = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("How old are you?")
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text("Metabolism can change with age")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .padding(.top, 8)

                Spacer()

                AgeScrollPicker(selectedAge: $age, minAge: 18, maxAge: 99)
                    .frame(height: 280)

                Spacer()

                Button {
                    onSave(age)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
        }
    }
}

// MARK: - Gender Editor (full-screen, matches GenderStepView)

struct ProfileGenderEditor: View {
    let currentGender: Gender
    let onSave: (Gender) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Gender?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("What's your gender?")
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text("Your metabolism is unique and it can vary by gender")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 16) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        SelectionCard(
                            symbolName: gender.symbolName,
                            title: gender.rawValue,
                            isSelected: selected == gender
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selected = gender
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    if let selected {
                        onSave(selected)
                    }
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle(isEnabled: selected != nil))
                .disabled(selected == nil)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
            .onAppear {
                selected = currentGender
            }
        }
    }
}

// MARK: - Weekly Goal Editor (full-screen, slider matching PaceStepView)

struct ProfileWeeklyGoalEditor: View {
    let maxValue: Int
    let currentWeightKg: Double
    let targetWeightKg: Double
    let heightCm: Double
    let age: Int
    let gender: Gender
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var goalGrams: Int

    private var weeklyDisplay: String {
        LebolFormatters.formatWeeklyRate(Double(goalGrams) / 1000.0, useMetric: true)
    }

    private var estimatedGoalDate: Date {
        NutritionCalculator.estimateGoalDate(
            currentWeight: currentWeightKg,
            targetWeight: targetWeightKg,
            weeklyGoalGrams: goalGrams
        )
    }

    private var estimatedDailyCalories: Int {
        NutritionCalculator.calculateDailyCalories(
            weightKg: currentWeightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            weeklyGoalGrams: goalGrams
        )
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    init(initialValue: Int, maxValue: Int = 1000, currentWeightKg: Double, targetWeightKg: Double, heightCm: Double, age: Int, gender: Gender, onSave: @escaping (Int) -> Void) {
        self.maxValue = min(maxValue, 1500)
        self.currentWeightKg = currentWeightKg
        self.targetWeightKg = targetWeightKg
        self.heightCm = heightCm
        self.age = age
        self.gender = gender
        self.onSave = onSave
        _goalGrams = State(initialValue: min(initialValue, min(maxValue, 1500)))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("Weekly goal")
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text("How much do you want to lose per week?")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()

                Text("Expected progress per week")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(weeklyDisplay)
                        .font(LebolFont.metricLarge())
                        .foregroundColor(.lebolTextPrimary)
                    Text("kg")
                        .font(LebolFont.title2())
                        .foregroundColor(.lebolTextSecondary)
                }
                .padding(.top, 8)

                // Pace slider
                Spacer().frame(height: 24)

                PaceSlider(goalGrams: $goalGrams)

                Spacer()

                // Goal date card
                InfoCard(
                    title: "Reach your goal by \(Self.dateFormatter.string(from: estimatedGoalDate))",
                    subtitle: "Daily calorie goal \u{2013} \(estimatedDailyCalories) kcal. It\u{2019}s balanced, sustainable, and supports your long term success goals."
                )

                Button {
                    onSave(goalGrams)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
        }
    }
}

// MARK: - Measurement System Editor (full-screen, matches GenderStepView pattern)

struct ProfileMeasurementSystemEditor: View {
    let currentUseMetric: Bool
    let onSave: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Bool?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("Measurement System")
                    .font(LebolFont.title())
                    .foregroundColor(.lebolTextPrimary)

                Text("Choose your preferred units")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 16) {
                    SelectionCard(
                        title: "Metric (kg, cm)",
                        isSelected: selected == true
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = true
                        }
                    }

                    SelectionCard(
                        title: "Imperial (lbs, ft)",
                        isSelected: selected == false
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = false
                        }
                    }
                }

                Spacer()

                Button {
                    if let selected {
                        onSave(selected)
                    }
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(LebolPrimaryButtonStyle(isEnabled: selected != nil))
                .disabled(selected == nil)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .lebolDismissToolbar()
            .onAppear {
                selected = currentUseMetric
            }
        }
    }
}
