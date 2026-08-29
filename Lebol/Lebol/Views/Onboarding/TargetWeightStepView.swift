import SwiftUI

struct TargetWeightStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("What's your target weight?")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)

            Text("Let's set a goal you can achieve")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
                .padding(.top, 8)

            TargetWeightPicker(
                targetWeightKg: $viewModel.targetWeightKg,
                useMetric: $viewModel.useMetric,
                currentWeightKg: viewModel.weightKg,
                showMeasurementSystemToggle: false
            )

            HealthyTargetInfoCard(heightCm: viewModel.heightCm, useMetric: viewModel.useMetric)

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(LebolPrimaryButtonStyle())
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .onAppear {
            if !viewModel.useMetric {
                let lbs = viewModel.targetWeightKg * NutritionCalculator.kgToLbs
                let snappedLbs = (lbs * 10).rounded() / 10
                viewModel.targetWeightKg = snappedLbs / NutritionCalculator.kgToLbs
            }
        }
    }
}
