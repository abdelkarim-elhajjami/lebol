import SwiftUI

struct MeasurementSystemStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var isAutoMetric: Bool { OnboardingViewModel.localeUsesMetric }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("Choose measurement system")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)
                .multilineTextAlignment(.center)

            Text("We'll use this across the app")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 16) {
                // Imperial option
                ZStack(alignment: .top) {
                    SelectionCard(
                        title: "lbs and ft",
                        subtitle: "Imperial",
                        isSelected: !viewModel.useMetric
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.useMetric = false
                        }
                    }

                    if !isAutoMetric {
                        autoDetectedBadge
                    }
                }

                // Metric option
                ZStack(alignment: .top) {
                    SelectionCard(
                        title: "kg and cm",
                        subtitle: "Metric",
                        isSelected: viewModel.useMetric
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.useMetric = true
                        }
                    }

                    if isAutoMetric {
                        autoDetectedBadge
                    }
                }
            }

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
    }

    private var autoDetectedBadge: some View {
        Text("Auto-detected")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.lebolTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.lebolBackground)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
            )
            .offset(y: -10)
    }
}
