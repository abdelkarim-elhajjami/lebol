import SwiftUI

struct HeightStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
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

            HeightPicker(heightCm: $viewModel.heightCm, useMetric: $viewModel.useMetric, showMeasurementSystemToggle: false)

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
}

// MARK: - Vertical Ruler for CM (scrollable, fine precision)
struct VerticalRulerCm: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double

    var body: some View {
        VerticalRuler(
            value: $value,
            minValue: minValue,
            maxValue: maxValue,
            pixelsPerUnit: 13,
            majorTickTest: { $0 % 10 == 0 },
            midTickTest: { $0 % 5 == 0 },
            labelFormatter: { "\($0)" }
        )
    }
}

// MARK: - Vertical Ruler for Feet/Inches
struct VerticalRulerFt: View {
    @Binding var valueCm: Double
    let minCm: Double
    let maxCm: Double

    private var minInches: Double { minCm / 2.54 }
    private var maxInches: Double { maxCm / 2.54 }

    private var inchesBinding: Binding<Double> {
        Binding<Double>(
            get: { valueCm / 2.54 },
            set: { newInches in
                valueCm = newInches * 2.54  // No rounding — preserves inch alignment
            }
        )
    }

    var body: some View {
        VerticalRuler(
            value: inchesBinding,
            minValue: minInches,
            maxValue: maxInches,
            pixelsPerUnit: 13,
            majorTickTest: { $0 % 12 == 0 },
            midTickTest: { $0 % 6 == 0 && $0 % 12 != 0 },
            labelFormatter: { "\($0 / 12)'" }
        )
    }
}
