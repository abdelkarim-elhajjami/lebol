import SwiftUI

struct PrivacyStepView: View {
    let viewModel: OnboardingViewModel

    // Pre-render guard
    @State private var hasAnimated = false

    // Staggered entrance states
    @State private var shieldAppeared = false
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var cardAppeared = false
    @State private var buttonAppeared = false

    // Continuous animation states
    @State private var glowPulse: CGFloat = 1.0
    @State private var shieldFloat: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Shield illustration with pulsing glow
            ZStack {
                // Pulsing outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.lebolPrimary.opacity(0.15),
                                Color.lebolPrimary.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(glowPulse)

                // Inner glow — slightly different phase
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.lebolPrimary.opacity(0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.15 + (glowPulse - 1.0) * 0.6)

                // Shield with checkmark
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.lebolPrimary,
                                    Color.lebolPrimaryDark
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.lebolPrimary.opacity(0.25), radius: 12, x: 0, y: 6)

                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: shieldFloat)
            }
            .frame(width: 200, height: 200)
            .scaleEffect(shieldAppeared ? 1 : 0.5)
            .opacity(shieldAppeared ? 1 : 0)

            Spacer().frame(height: 28)

            Text("Thank you for trusting us")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)
                .multilineTextAlignment(.center)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 16)

            Spacer().frame(height: 8)

            Text("Now let\u{2019}s personalize Lebol for you")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
                .opacity(subtitleAppeared ? 1 : 0)
                .offset(y: subtitleAppeared ? 0 : 12)

            Spacer().frame(height: 36)

            // Privacy card
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.lebolPrimary, Color.lebolPrimaryDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Your privacy and security matter to us")
                    .font(LebolFont.headline())
                    .foregroundColor(.lebolTextPrimary)
                    .multilineTextAlignment(.center)

                Text("We promise to always protect your personal information and keep it confidential.")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.lebolCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .scaleEffect(cardAppeared ? 1 : 0.95)
            .opacity(cardAppeared ? 1 : 0)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(LebolPrimaryButtonStyle())
            .opacity(buttonAppeared ? 1 : 0)

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 24)
        .task(id: viewModel.currentStep) {
            guard viewModel.currentStep == .privacy, !hasAnimated else { return }
            hasAnimated = true
            startAnimations()
        }
    }

    private func startAnimations() {
        // 1. Shield entrance — spring bounce
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            shieldAppeared = true
        }

        // 2. Title — slides up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            titleAppeared = true
        }

        // 3. Subtitle
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.45)) {
            subtitleAppeared = true
        }

        // 4. Card — scale + fade
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            cardAppeared = true
        }

        // 5. Button
        withAnimation(.easeOut(duration: 0.4).delay(0.75)) {
            buttonAppeared = true
        }

        // Continuous animations — start after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Shield float
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                shieldFloat = -4
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                glowPulse = 1.08
            }
        }
    }
}
