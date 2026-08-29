import SwiftUI
import AuthenticationServices

struct AccountCreationStepView: View {
    let viewModel: OnboardingViewModel
    @Bindable var authViewModel: AuthViewModel
    let onSkip: () -> Void

    @State private var imageOffset: CGFloat = 0

    // Food image grid — SF Symbols as placeholders for the food collage
    private let foodImages = [
        "fork.knife", "cup.and.saucer.fill", "leaf.fill",
        "carrot.fill", "fish.fill", "birthday.cake.fill",
        "takeoutbag.and.cup.and.straw.fill", "mug.fill", "popcorn.fill"
    ]

    var body: some View {
        ZStack {
            // Background food collage
            foodCollageBackground

            // Content overlay
            VStack(spacing: 0) {
                // X button (top-right)
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.lebolTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Bottom card
                VStack(spacing: 20) {
                    Text("You\u{2019}re almost there!")
                        .font(LebolFont.title2())
                        .foregroundColor(.lebolTextPrimary)

                    Text("Use your account to keep your personalization at your fingertips")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    // Continue with Apple
                    SignInWithAppleButton(.continue) { request in
                        let appleRequest = authViewModel.prepareAppleSignIn()
                        request.requestedScopes = appleRequest.requestedScopes
                        request.nonce = appleRequest.nonce
                    } onCompletion: { result in
                        Task {
                            if let userId = await authViewModel.handleAppleSignIn(result: result) {
                                authViewModel.linkAuthToProfile(userId: userId)
                                viewModel.nextStep()
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(28)

                    // Continue with Google
                    Button {
                        Task {
                            if let userId = await authViewModel.signInWithGoogle() {
                                authViewModel.linkAuthToProfile(userId: userId)
                                viewModel.nextStep()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("G")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.red)
                            Text("Continue with Google")
                                .font(LebolFont.headline())
                                .foregroundColor(.lebolTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        )
                    }

                    if let error = authViewModel.error {
                        Text(error)
                            .font(LebolFont.caption())
                            .foregroundColor(.lebolError)
                    }
                }
                .padding(24)
                .padding(.bottom, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 16, y: -4)
                )
            }
        }
        .background(Color.lebolBackground)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                imageOffset = -60
            }
        }
    }

    private var foodCollageBackground: some View {
        GeometryReader { geo in
            let columns = 3
            let cellSize = geo.size.width / CGFloat(columns)

            VStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<columns, id: \.self) { col in
                            let index = (row * columns + col) % foodImages.count
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.lebolSurface)
                                .frame(width: cellSize - 4, height: cellSize - 4)
                                .overlay(
                                    Image(systemName: foodImages[index])
                                        .font(.system(size: 32))
                                        .foregroundColor(.lebolTextTertiary)
                                )
                        }
                    }
                }
            }
            .offset(y: imageOffset)
        }
        .clipped()
    }
}

// Helper extension for linking auth without direct profile access
extension AuthViewModel {
    func linkAuthToProfile(userId: String) {
        // Profile linking happens in completeOnboarding via OnboardingContainerView
        signedInFromWelcome = false // Not from welcome — from accountCreation step
    }
}
