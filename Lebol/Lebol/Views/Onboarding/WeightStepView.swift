import SwiftUI

struct WeightStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("What's your weight?")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)

            Text("This is where your journey begins")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
                .padding(.top, 8)

            Spacer().frame(height: 24)

            WeightPicker(weightKg: $viewModel.weightKg, useMetric: $viewModel.useMetric, showMeasurementSystemToggle: false)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(LebolPrimaryButtonStyle())
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Snap kg to nearest 0.1 lbs equivalent so indicator aligns with lbs tick marks
            if !viewModel.useMetric {
                let lbs = viewModel.weightKg * NutritionCalculator.kgToLbs
                let snappedLbs = (lbs * 10).rounded() / 10
                viewModel.weightKg = snappedLbs / NutritionCalculator.kgToLbs
            }
        }
    }
}

// MARK: - Horizontal Ruler for KG
struct HorizontalRulerKg: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    var showWarningZone: Bool = false
    var snapStep: Double = 0.1

    var body: some View {
        HorizontalRuler(
            value: $value,
            minValue: minValue,
            maxValue: maxValue,
            pixelsPerUnit: 130,
            tickStep: 0.1,
            majorTickEvery: 1,
            midTickEvery: nil,
            snapStep: snapStep,
            showWarningZone: showWarningZone
        )
    }
}

// MARK: - Horizontal Ruler for LBS (displays lbs values, stores kg internally)
struct HorizontalRulerLbs: View {
    @Binding var valueKg: Double
    let minKg: Double
    let maxKg: Double
    var showWarningZone: Bool = false
    var snapStep: Double = 0.1

    private var minLbs: Double { minKg * NutritionCalculator.kgToLbs }
    private var maxLbs: Double { maxKg * NutritionCalculator.kgToLbs }

    private var lbsBinding: Binding<Double> {
        Binding<Double>(
            get: { valueKg * NutritionCalculator.kgToLbs },
            set: { newLbs in
                valueKg = newLbs / NutritionCalculator.kgToLbs
            }
        )
    }

    var body: some View {
        HorizontalRuler(
            value: lbsBinding,
            minValue: minLbs,
            maxValue: maxLbs,
            pixelsPerUnit: 130,
            tickStep: 0.1,
            majorTickEvery: 1,
            midTickEvery: nil,
            snapStep: snapStep,
            showWarningZone: showWarningZone
        )
    }
}
