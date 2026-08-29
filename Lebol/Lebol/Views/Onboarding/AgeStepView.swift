import SwiftUI

struct AgeStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
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

            // Custom scroll wheel picker
            AgeScrollPicker(selectedAge: $viewModel.selectedAge, minAge: 18, maxAge: 99)
                .frame(height: 280)

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
