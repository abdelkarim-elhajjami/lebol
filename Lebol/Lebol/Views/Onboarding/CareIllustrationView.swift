import SwiftUI

struct CareIllustrationView: View {
    // Sparkle star colors (illustration-specific, not design system tokens)
    private let goldBright = Color(red: 1.0, green: 0.84, blue: 0.31)  // #FFD64F
    private let goldMedium = Color(red: 1.0, green: 0.78, blue: 0.24)  // #FFC73D
    private let goldSoft   = Color(red: 1.0, green: 0.88, blue: 0.40)  // #FFE066

    // Animation states
    @State private var blob1Offset: CGFloat = 0
    @State private var blob2Offset: CGFloat = 0
    @State private var blob3Offset: CGFloat = 0
    @State private var blob4Scale: CGFloat = 1.0
    @State private var heartScale: CGFloat = 1.0
    @State private var heartFloat: CGFloat = 0
    @State private var sparkle1Opacity: Double = 0.0
    @State private var sparkle2Opacity: Double = 0.0
    @State private var sparkle3Opacity: Double = 0.0
    @State private var orbitAngle: Double = 0

    var body: some View {
        ZStack {
            // Outermost soft glow — very subtle teal wash
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.lebolPrimary.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            // Blob 1 — bottom-left, deep teal
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.lebolPrimaryDark.opacity(0.55),
                            Color.lebolPrimary.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 22)
                .offset(x: -32, y: 22 + blob1Offset)

            // Blob 2 — top-right, light mint
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.lebolPrimaryLight.opacity(0.50),
                            Color.lebolPrimaryVeryLight.opacity(0.60)
                        ],
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 85, height: 85)
                .blur(radius: 18)
                .offset(x: 30, y: -24 + blob2Offset)

            // Blob 3 — center-right, warm cyan accent
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.lebolPrimaryDark.opacity(0.45),
                            Color.lebolPrimary.opacity(0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 70, height: 70)
                .blur(radius: 16)
                .offset(x: 18, y: 15 + blob3Offset)

            // Blob 4 — top-left, very light teal, pulsing
            Circle()
                .fill(
                    Color.lebolPrimaryLight.opacity(0.3)
                )
                .frame(width: 60, height: 60)
                .blur(radius: 14)
                .scaleEffect(blob4Scale)
                .offset(x: -18, y: -30)

            // Golden sparkle stars — orbiting elegantly around the heart
            GoldenStar()
                .fill(goldBright)
                .frame(width: 20, height: 20)
                .shadow(color: goldBright.opacity(0.6), radius: 6)
                .offset(x: orbitX(radius: 68, angle: orbitAngle + 0),
                         y: orbitY(radius: 68, angle: orbitAngle + 0))
                .opacity(0.3 + sparkle1Opacity * 0.7)

            GoldenStar()
                .fill(goldMedium)
                .frame(width: 15, height: 15)
                .shadow(color: goldMedium.opacity(0.5), radius: 5)
                .offset(x: orbitX(radius: 72, angle: orbitAngle + 135),
                         y: orbitY(radius: 72, angle: orbitAngle + 135))
                .opacity(0.3 + sparkle2Opacity * 0.7)

            GoldenStar()
                .fill(goldSoft)
                .frame(width: 11, height: 11)
                .shadow(color: goldSoft.opacity(0.45), radius: 4)
                .offset(x: orbitX(radius: 60, angle: orbitAngle + 250),
                         y: orbitY(radius: 60, angle: orbitAngle + 250))
                .opacity(0.3 + sparkle3Opacity * 0.7)

            // Heart — clean white with teal-tinted shadow
            Image(systemName: "heart.fill")
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.lebolPrimary.opacity(0.30), radius: 16, x: 0, y: 8)
            .scaleEffect(heartScale)
            .offset(y: heartFloat)
        }
        .frame(width: 220, height: 220)
        .onAppear { startAnimations() }
    }

    // Elliptical orbit — slightly wider than tall for elegance
    private func orbitX(radius: CGFloat, angle: Double) -> CGFloat {
        CGFloat(cos(angle * .pi / 180)) * radius
    }

    private func orbitY(radius: CGFloat, angle: Double) -> CGFloat {
        CGFloat(sin(angle * .pi / 180)) * radius * 0.6
    }

    private func startAnimations() {
        // Blobs — slow independent drifts
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            blob1Offset = -8
        }
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(0.5)) {
            blob2Offset = 7
        }
        withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true).delay(1.0)) {
            blob3Offset = -6
        }

        // Blob 4 — gentle pulse
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.3)) {
            blob4Scale = 1.15
        }

        // Heart — float + gentle pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.2)) {
            heartFloat = -4
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) {
            heartScale = 1.05
        }

        // Sparkles — twinkle + slow orbit around heart
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            sparkle1Opacity = 1.0
        }
        withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true).delay(0.3)) {
            sparkle2Opacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.6)) {
            sparkle3Opacity = 1.0
        }

        // Slow elegant orbit
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            orbitAngle = 360
        }
    }
}

// MARK: - 4-Pointed Star Shape

private struct GoldenStar: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.35

        var path = Path()
        for i in 0..<4 {
            let angle = Double(i) * .pi / 2 - .pi / 2
            let outerX = cx + CGFloat(cos(angle)) * r
            let outerY = cy + CGFloat(sin(angle)) * r

            let midAngle = angle + .pi / 4
            let innerX = cx + CGFloat(cos(midAngle)) * inner
            let innerY = cy + CGFloat(sin(midAngle)) * inner

            if i == 0 {
                path.move(to: CGPoint(x: outerX, y: outerY))
            } else {
                path.addLine(to: CGPoint(x: outerX, y: outerY))
            }
            path.addLine(to: CGPoint(x: innerX, y: innerY))
        }
        path.closeSubpath()
        return path
    }
}
