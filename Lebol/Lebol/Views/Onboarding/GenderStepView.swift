import SwiftUI

struct GenderStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
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
                        isSelected: viewModel.selectedGender == gender
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedGender = gender
                        }
                    }
                }
            }

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(LebolPrimaryButtonStyle(isEnabled: viewModel.canContinue))
            .disabled(!viewModel.canContinue)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}
