import SwiftUI

struct WelcomeStepView: View {
    let viewModel: OnboardingViewModel
    @Bindable var authViewModel: AuthViewModel
    @State private var showSignInSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            // Logo — "Le" black + "bol" teal
            HStack(spacing: 0) {
                Text("Le")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.lebolTextPrimary)
                Text("bol")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.lebolPrimary)
            }

            Spacer()

            // Thumbs up icon
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 48))
                .foregroundColor(.lebolPrimary)

            Spacer().frame(height: 16)

            // Laurel wreath with motivational text
            HStack(spacing: 0) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 80))
                    .foregroundColor(.lebolPrimaryLight)

                VStack(spacing: 4) {
                    Text("Starting out is")
                    Text("the hardest part -")
                    Text("and you\u{2019}ve already")
                    Text("done it!")
                }
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.lebolPrimary)
                .multilineTextAlignment(.center)

                Image(systemName: "laurel.trailing")
                    .font(.system(size: 80))
                    .foregroundColor(.lebolPrimaryLight)
            }
            .padding(.horizontal, -8)

            Spacer().frame(height: 48)

            Text("Let\u{2019}s personalize\nyour journey together")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.lebolTextPrimary)
                .multilineTextAlignment(.center)

            Spacer()

            // Continue button
            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(LebolPrimaryButtonStyle())

            Spacer().frame(height: 12)

            // Sign in link for returning users
            HStack(spacing: 4) {
                Text("I already have an account")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                Button("Sign In") {
                    showSignInSheet = true
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.lebolTextPrimary)
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showSignInSheet) {
            SignInView(authViewModel: authViewModel)
        }
    }
}
