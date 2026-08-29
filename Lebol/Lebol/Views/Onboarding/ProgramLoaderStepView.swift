import SwiftUI

struct ProgramLoaderStepView: View {
    let viewModel: OnboardingViewModel

    // Pre-render guard
    @State private var hasStarted = false

    // Row states
    @State private var activeRow: Int = -1 // -1=not started, 0=row1 active, 1=row2 active, 2=all done
    @State private var row1Progress: Double = 0.0
    @State private var row2Progress: Double = 0.0
    @State private var row1Complete = false
    @State private var row2Complete = false
    @State private var row1BarVisible = false
    @State private var row2BarVisible = false

    // Shimmer
    @State private var shimmerPhase: CGFloat = -1.0

    // Durations — unhurried, ~8.4s total
    private let row1Duration: Double = 3.5
    private let row1PauseBefore: Double = 0.5
    private let gapBetweenRows: Double = 0.6
    private let row2Duration: Double = 3.0
    private let postCompletePause: Double = 0.8

    // Keyframes: (time%, progress%) — organic bursts + slowdowns
    private let row1Keyframes: [(Double, Double)] = [
        (0.00, 0.00),
        (0.05, 0.12),  // quick initial burst
        (0.15, 0.22),  // slows down
        (0.25, 0.28),  // near-stall
        (0.40, 0.38),  // slow crawl
        (0.55, 0.52),  // gradual pickup
        (0.70, 0.65),  // accelerating
        (0.80, 0.78),  // faster
        (0.90, 0.92),  // almost done
        (0.95, 0.97),  // final push
        (1.00, 1.00),
    ]

    private let row2Keyframes: [(Double, Double)] = [
        (0.00, 0.00),
        (0.08, 0.18),  // faster initial
        (0.20, 0.30),
        (0.35, 0.40),  // processing...
        (0.50, 0.55),
        (0.65, 0.68),
        (0.75, 0.80),
        (0.85, 0.90),
        (0.95, 0.98),
        (1.00, 1.00),
    ]

    private var heightDisplay: String {
        if viewModel.useMetric {
            return "\(Int(viewModel.heightCm)) cm"
        } else {
            let totalInches = viewModel.heightCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\" ft"
        }
    }

    private var weightDisplay: String {
        if viewModel.useMetric {
            return "\(String(format: "%.1f", viewModel.weightKg)) kg"
        } else {
            return "\(String(format: "%.1f", viewModel.weightKg * NutritionCalculator.kgToLbs)) lbs"
        }
    }

    private var caloriesDisplay: String {
        "\(viewModel.dailyCalorieTarget) kcal"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text("Customizing your program")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 56)

            // Row 1: Analyzing profile
            LoaderRowView(
                label: "Analyzing profile",
                value: "\(heightDisplay), \(weightDisplay)",
                progress: row1Progress,
                isActive: activeRow >= 0,
                isComplete: row1Complete,
                barVisible: row1BarVisible,
                shimmerPhase: shimmerPhase
            )
            .padding(.horizontal, 8)

            Spacer().frame(height: 32)

            // Row 2: Metabolism insights
            LoaderRowView(
                label: "Metabolism insights",
                value: caloriesDisplay,
                progress: row2Progress,
                isActive: activeRow >= 1,
                isComplete: row2Complete,
                barVisible: row2BarVisible,
                shimmerPhase: shimmerPhase
            )
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
        .task(id: viewModel.currentStep) {
            guard viewModel.currentStep == .programLoader, !hasStarted else { return }
            hasStarted = true
            startShimmer()
            await runAnimationSequence()
        }
    }

    // MARK: - Keyframe interpolation

    private func interpolateKeyframes(_ keyframes: [(Double, Double)], at t: Double) -> Double {
        let clamped = min(max(t, 0), 1)

        for i in 0..<(keyframes.count - 1) {
            let (t0, p0) = keyframes[i]
            let (t1, p1) = keyframes[i + 1]

            if clamped >= t0 && clamped <= t1 {
                let segmentT = (clamped - t0) / (t1 - t0)
                let smoothed = segmentT * segmentT * (3 - 2 * segmentT)
                return p0 + (p1 - p0) * smoothed
            }
        }

        return clamped
    }

    // MARK: - Shimmer animation

    private func startShimmer() {
        withAnimation(
            .linear(duration: 1.8)
            .repeatForever(autoreverses: false)
        ) {
            shimmerPhase = 2.0
        }
    }

    // MARK: - Animation sequence (structured concurrency)

    private func runAnimationSequence() async {
        // Pause before starting
        try? await Task.sleep(for: .seconds(row1PauseBefore))
        guard !Task.isCancelled else { return }

        // Start row 1
        withAnimation(.easeOut(duration: 0.3)) {
            activeRow = 0
            row1BarVisible = true
        }
        await animateProgress(keyframes: row1Keyframes, duration: row1Duration) { row1Progress = $0 }
        guard !Task.isCancelled else { return }

        // Complete row 1
        row1Progress = 1.0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            row1Complete = true
        }
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation(.easeOut(duration: 0.25)) {
            row1BarVisible = false
        }

        // Gap between rows
        try? await Task.sleep(for: .seconds(gapBetweenRows - 0.3))
        guard !Task.isCancelled else { return }

        // Start row 2
        withAnimation(.easeOut(duration: 0.3)) {
            activeRow = 1
            row2BarVisible = true
        }
        await animateProgress(keyframes: row2Keyframes, duration: row2Duration) { row2Progress = $0 }
        guard !Task.isCancelled else { return }

        // Complete row 2
        row2Progress = 1.0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            row2Complete = true
        }
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation(.easeOut(duration: 0.25)) {
            row2BarVisible = false
        }

        // Post-complete pause then advance
        try? await Task.sleep(for: .seconds(postCompletePause))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            activeRow = 2
        }
        viewModel.nextStep()
    }

    private func animateProgress(
        keyframes: [(Double, Double)],
        duration: Double,
        update: @escaping (Double) -> Void
    ) async {
        let start = Date()
        let frameInterval: UInt64 = 16_666_667 // ~60fps in nanoseconds

        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            let linearT = min(elapsed / duration, 1.0)
            let eased = interpolateKeyframes(keyframes, at: linearT)
            update(eased)

            if linearT >= 1.0 { break }
            try? await Task.sleep(nanoseconds: frameInterval)
        }
    }
}

// MARK: - Loader Row View

private struct LoaderRowView: View {
    let label: String
    let value: String
    let progress: Double
    let isActive: Bool
    let isComplete: Bool
    let barVisible: Bool
    let shimmerPhase: CGFloat

    private let barHeight: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label row with status indicator
            HStack(spacing: 12) {
                // Status indicator on the left
                ZStack {
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.lebolPrimary)
                            .transition(.scale.combined(with: .opacity))
                    } else if isActive {
                        ProgressView()
                            .controlSize(.regular)
                            .tint(.lebolPrimary)
                            .transition(.opacity)
                    } else {
                        Circle()
                            .stroke(Color.lebolTextTertiary.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                    }
                }
                .frame(width: 26, height: 26)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isComplete)
                .animation(.easeOut(duration: 0.3), value: isActive)

                // Label + value
                Text(label + ": ")
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                +
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.lebolTextPrimary)

                Spacer()
            }

            // Wide progress bar with percentage INSIDE
            if barVisible {
                GeometryReader { geo in
                    let fillWidth = max(barHeight, geo.size.width * progress)

                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .fill(Color.lebolDivider)
                            .frame(height: barHeight)

                        // Filled portion with gradient
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.lebolPrimary, Color.lebolPrimaryLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillWidth, height: barHeight)
                            .overlay(
                                // Shimmer highlight sweeping across
                                RoundedRectangle(cornerRadius: barHeight / 2)
                                    .fill(
                                        LinearGradient(
                                            stops: [
                                                .init(color: .clear, location: 0),
                                                .init(color: .white.opacity(0.25), location: 0.5),
                                                .init(color: .clear, location: 1),
                                            ],
                                            startPoint: UnitPoint(x: shimmerPhase - 0.3, y: 0.5),
                                            endPoint: UnitPoint(x: shimmerPhase, y: 0.5)
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: barHeight / 2))
                            )
                            .shadow(color: Color.lebolPrimary.opacity(0.2), radius: 4, x: 0, y: 2)

                        // Percentage text inside the bar
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                            .padding(.leading, 16)
                    }
                }
                .frame(height: barHeight)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.92, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }
        }
        .opacity(isActive || isComplete ? 1.0 : 0.35)
        .animation(.easeOut(duration: 0.3), value: isActive)
    }
}
