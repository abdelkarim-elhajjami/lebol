import SwiftUI

struct PaceStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    private var weeklyDisplay: String {
        LebolFormatters.formatWeeklyRate(viewModel.weeklyLossKg, useMetric: viewModel.useMetric)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("Pick a pace that works for you")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)
                .multilineTextAlignment(.center)

            Spacer()

            Text("Expected progress per week")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(weeklyDisplay)
                    .font(LebolFont.metricLarge())
                    .foregroundColor(.lebolTextPrimary)
                Text(viewModel.useMetric ? "kg" : "lbs")
                    .font(LebolFont.title2())
                    .foregroundColor(.lebolTextSecondary)
            }
            .padding(.top, 8)

            // Pace slider
            Spacer().frame(height: 24)

            PaceSlider(goalGrams: $viewModel.weeklyGoalGrams)

            Spacer()

            // Goal date card
            InfoCard(
                title: "Reach your goal by \(Self.dateFormatter.string(from: viewModel.estimatedGoalDate))",
                subtitle: "Daily calorie goal \u{2013} \(viewModel.dailyCalorieTarget) kcal. It\u{2019}s balanced, sustainable, and supports your long term success goals."
            )

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
    }
}
