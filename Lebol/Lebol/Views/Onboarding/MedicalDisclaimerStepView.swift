import SwiftUI

struct MedicalDisclaimerStepView: View {
    let viewModel: OnboardingViewModel

    @State private var hasAnimated = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated teal gradient illustration
            CareIllustrationView()
                .scaleEffect(hasAnimated ? 1.0 : 0.5)
                .opacity(hasAnimated ? 1.0 : 0)

            Spacer().frame(height: 28)

            Text("Guiding you with care")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)
                .multilineTextAlignment(.center)
                .opacity(hasAnimated ? 1.0 : 0)
                .offset(y: hasAnimated ? 0 : 12)

            Spacer().frame(height: 20)

            Text("Lebol helps you track your calories and nutrition with personalized daily goals based on your profile.")
                .font(LebolFont.body())
                .foregroundColor(.lebolTextSecondary)
                .multilineTextAlignment(.center)
                .opacity(hasAnimated ? 1.0 : 0)
                .offset(y: hasAnimated ? 0 : 12)

            Spacer().frame(height: 20)

            Text("However, our app is not a substitute for professional medical advice. Before starting any new diet or if you have health concerns, always consult a qualified healthcare professional.")
                .font(LebolFont.body())
                .foregroundColor(.lebolTextSecondary)
                .multilineTextAlignment(.center)
                .opacity(hasAnimated ? 1.0 : 0)
                .offset(y: hasAnimated ? 0 : 12)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Okay, got it")
            }
            .buttonStyle(LebolPrimaryButtonStyle())
            .opacity(hasAnimated ? 1.0 : 0)
            .offset(y: hasAnimated ? 0 : 8)

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 24)
        .task(id: viewModel.currentStep) {
            guard viewModel.currentStep == .medicalDisclaimer, !hasAnimated else { return }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15)) {
                hasAnimated = true
            }
        }
    }
}
