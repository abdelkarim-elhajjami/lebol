import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case privacy
    case gender
    case measurementSystem
    case age
    case height
    case weight
    case medicalDisclaimer
    case targetWeight
    case pace
    case programLoader
    case accountCreation
    case roadmap

    var sectionIndex: Int {
        switch self {
        case .welcome, .privacy: return 0
        case .gender, .measurementSystem, .age, .height, .weight, .medicalDisclaimer: return 1
        case .targetWeight, .pace, .programLoader, .accountCreation, .roadmap: return 2
        }
    }

    var showsProgressBar: Bool {
        switch self {
        case .welcome, .privacy, .programLoader, .accountCreation, .roadmap: return false
        default: return true
        }
    }

    /// Steps with drag-dependent UI (pickers/rulers) need drag gestures passed through to subviews.
    var hasDragDependentUI: Bool {
        switch self {
        case .age, .height, .weight, .targetWeight, .pace:
            return true
        default:
            return false
        }
    }
}

@MainActor @Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var selectedGender: Gender?
    var selectedAge: Int = 30
    var heightCm: Double = 170
    var useMetric: Bool = OnboardingViewModel.localeUsesMetric
    var weightKg: Double = 80
    var targetWeightKg: Double = 65
    var weeklyGoalGrams: Int = 800

    /// Auto-detect measurement system from device locale
    static var localeUsesMetric: Bool {
        Locale.current.measurementSystem == .metric
    }

    var canContinue: Bool {
        if currentStep == .gender { return selectedGender != nil }
        return true
    }

    var progressInSection: Double {
        let allSteps = OnboardingStep.allCases.filter { $0.showsProgressBar }
        let sectionSteps = allSteps.filter { $0.sectionIndex == currentStep.sectionIndex }
        guard let indexInSection = sectionSteps.firstIndex(of: currentStep) else { return 0 }
        return Double(indexInSection + 1) / Double(sectionSteps.count)
    }

    var recommendedTargetWeight: Double {
        NutritionCalculator.recommendedTargetWeight(heightCm: heightCm)
    }

    var dailyCalorieTarget: Int {
        let gender = selectedGender ?? .male
        return NutritionCalculator.calculateDailyCalories(
            weightKg: weightKg,
            heightCm: heightCm,
            age: selectedAge,
            gender: gender,
            weeklyGoalGrams: weeklyGoalGrams
        )
    }

    var macros: (carbs: Int, protein: Int, fats: Int) {
        NutritionCalculator.calculateMacros(dailyCalories: dailyCalorieTarget, weightKg: weightKg)
    }

    var estimatedGoalDate: Date {
        NutritionCalculator.estimateGoalDate(
            currentWeight: weightKg,
            targetWeight: targetWeightKg,
            weeklyGoalGrams: weeklyGoalGrams
        )
    }

    var waterGoal: Int {
        NutritionCalculator.calculateWaterGoal(weightKg: weightKg)
    }

    var weeklyLossKg: Double {
        Double(weeklyGoalGrams) / 1000.0
    }

    /// Whether the user is already at a healthy weight (BMI ≤ 24.9).
    var isHealthyWeight: Bool {
        NutritionCalculator.bmi(weightKg: weightKg, heightCm: heightCm) <= 24.9
    }

    /// Set by AuthViewModel when user signs in from welcome screen (skip accountCreation step)
    var skipAccountCreation = false

    func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }

        // Skip target weight + pace for users already at healthy BMI
        if nextIndex == .targetWeight && isHealthyWeight {
            targetWeightKg = weightKg
            weeklyGoalGrams = 0
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .programLoader
            }
            return
        }

        // Skip accountCreation if user already signed in from welcome screen
        if nextIndex == .accountCreation && skipAccountCreation {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .roadmap
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextIndex
        }
    }

    func previousStep() {
        // No going back from roadmap, programLoader, or accountCreation (non-interactive transition screens)
        if currentStep == .roadmap || currentStep == .programLoader || currentStep == .accountCreation {
            return
        }
        guard let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevIndex
        }
    }

    func createProfile(modelContext: ModelContext) -> UserProfile {
        let m = macros
        let profile = UserProfile(
            gender: selectedGender ?? .male,
            age: selectedAge,
            heightCm: heightCm,
            weightKg: weightKg,
            startingWeightKg: weightKg,
            targetWeightKg: targetWeightKg,
            weeklyGoalGrams: weeklyGoalGrams,
            dailyCalorieTarget: dailyCalorieTarget,
            dailyCarbsTarget: m.carbs,
            dailyProteinTarget: m.protein,
            dailyFatsTarget: m.fats,
            waterGoalMl: waterGoal,
            useMetric: useMetric
        )
        modelContext.insert(profile)

        let weightEntry = WeightEntry(weightKg: weightKg)
        modelContext.insert(weightEntry)

        let dailyLog = DailyLog()
        modelContext.insert(dailyLog)

        modelContext.saveWithLogging()
        return profile
    }
}
