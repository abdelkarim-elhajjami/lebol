import SwiftUI

struct RoadmapStepView: View {
    let viewModel: OnboardingViewModel
    var onComplete: (() -> Void)?

    // Milestone opacity (pure soft fade)
    @State private var m1Opacity: Double = 0
    @State private var m2Opacity: Double = 0
    @State private var m3Opacity: Double = 0

    // Line grow scale (0 = hidden, 1 = full height)
    @State private var line1Scale: CGFloat = 0
    @State private var line2Scale: CGFloat = 0

    // Button
    @State private var buttonVisible = false

    // Prevent re-animation on TabView pre-render
    @State private var hasAnimated = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    private var weightToLose: Double {
        max(0, viewModel.weightKg - viewModel.targetWeightKg)
    }

    private var oneWeekDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
    }

    private var oneWeekWeight: Double {
        viewModel.weightKg - viewModel.weeklyLossKg
    }

    private var isMaintenanceMode: Bool {
        viewModel.weeklyGoalGrams == 0
    }

    private var monthsToGoal: Int {
        guard !isMaintenanceMode, viewModel.weeklyLossKg > 0 else { return 0 }
        let weeks = weightToLose / viewModel.weeklyLossKg
        return max(1, Int(ceil(weeks / 4.33))) // 4.33 = average weeks per month (52/12)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            Text("See what\u{2019}s ahead")
                .font(LebolFont.title())
                .foregroundColor(.lebolTextPrimary)

            Spacer().frame(height: 36)

            if isMaintenanceMode {
                maintenanceTimeline
            } else {
                weightLossTimeline
            }

            Spacer()

            if buttonVisible {
                Button {
                    onComplete?()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 24)
        .task(id: viewModel.currentStep) {
            guard viewModel.currentStep == .roadmap, !hasAnimated else { return }
            hasAnimated = true
            try? await Task.sleep(for: .milliseconds(400))
            startAnimation()
        }
    }

    // MARK: - Weight Loss Timeline

    private var weightLossTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            MilestoneRow(
                iconType: .filled,
                title: "Today \u{2013} \(Self.dateFormatter.string(from: Date())) \u{2013} \(formattedWeight(viewModel.weightKg))",
                subtitle: "You want to lose \(formattedWeight(weightToLose))",
                showLine: true,
                lineScale: line1Scale
            )
            .opacity(m1Opacity)

            MilestoneRow(
                iconType: .filled,
                title: "In 1 week \u{2013} \(Self.dateFormatter.string(from: oneWeekDate)) \u{2013} \(formattedWeight(oneWeekWeight))",
                subtitle: "You\u{2019}ll see your first results \u{2014} around \(formattedWeightSmall(viewModel.weeklyLossKg)) down. This is the first win that comes from fixing habits and building a healthier relationship with food",
                showLine: true,
                lineScale: line2Scale
            )
            .opacity(m2Opacity)

            MilestoneRow(
                iconType: .target,
                title: "In \(monthsToGoal) month\(monthsToGoal == 1 ? "" : "s") \u{2013} \(Self.dateFormatter.string(from: viewModel.estimatedGoalDate)) \u{2013} \(formattedWeight(viewModel.targetWeightKg))",
                subtitle: "You\u{2019}ll reach your goal of losing \(formattedWeight(weightToLose)). You\u{2019}ll feel better, more energetic, and proud of how far you\u{2019}ve come.",
                showLine: false,
                lineScale: 0
            )
            .opacity(m3Opacity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Maintenance Timeline

    private var maintenanceTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            MilestoneRow(
                iconType: .filled,
                title: "Today \u{2013} \(Self.dateFormatter.string(from: Date())) \u{2013} \(formattedWeight(viewModel.weightKg))",
                subtitle: "You\u{2019}re at a healthy weight. Let\u{2019}s keep it that way!",
                showLine: true,
                lineScale: line1Scale
            )
            .opacity(m1Opacity)

            MilestoneRow(
                iconType: .target,
                title: "Your goal: maintain \(formattedWeight(viewModel.weightKg))",
                subtitle: "We\u{2019}ll help you stay on track with balanced nutrition and daily logging.",
                showLine: false,
                lineScale: 0
            )
            .opacity(m2Opacity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Animation

    private func startAnimation() {
        let milestoneCount = isMaintenanceMode ? 2 : 3

        // Step 1: First milestone softly materializes
        withAnimation(.easeInOut(duration: 0.8)) {
            m1Opacity = 1
        }

        // Step 2: Line 1 grows downward
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.7)) {
                line1Scale = 1
            }
        }

        // Step 3: Second milestone softly materializes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                m2Opacity = 1
            }
        }

        if milestoneCount == 3 {
            // Step 4: Line 2 grows downward
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeInOut(duration: 0.7)) {
                    line2Scale = 1
                }
            }

            // Step 5: Third milestone softly materializes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    m3Opacity = 1
                }
            }
        }

        // Step 6: Button fades in
        let buttonDelay = milestoneCount == 3 ? 4.4 : 2.8
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                buttonVisible = true
            }
        }
    }

    // MARK: - Helpers

    private func formattedWeight(_ kg: Double) -> String {
        if viewModel.useMetric {
            return "\(String(format: "%.1f", kg)) kg"
        } else {
            return "\(String(format: "%.1f", kg * NutritionCalculator.kgToLbs)) lbs"
        }
    }

    private func formattedWeightSmall(_ kg: Double) -> String {
        if viewModel.useMetric {
            let grams = Int(kg * 1000)
            return "\(grams) g"
        } else {
            return "\(String(format: "%.1f", kg * NutritionCalculator.kgToLbs)) lbs"
        }
    }
}

// MARK: - Milestone Row

private enum MilestoneIconType {
    case filled, target
}

private struct MilestoneRow: View {
    let iconType: MilestoneIconType
    let title: String
    let subtitle: String
    let showLine: Bool
    let lineScale: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left column: circle + line below
            VStack(spacing: 0) {
                ZStack {
                    switch iconType {
                    case .filled:
                        Circle()
                            .stroke(Color.lebolPrimary, lineWidth: 3.5)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.white))
                    case .target:
                        ZStack {
                            Circle()
                                .stroke(Color.lebolPrimary, lineWidth: 3)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.white))
                            Circle()
                                .stroke(Color.lebolPrimary, lineWidth: 2)
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color.lebolPrimary)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .frame(width: 28, height: 28)

                if showLine {
                    Rectangle()
                        .fill(Color.lebolPrimary.opacity(0.35))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                        .scaleEffect(y: lineScale, anchor: .top)
                        .opacity(lineScale)
                }
            }
            .frame(width: 28)

            // Right column: text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LebolFont.headline())
                    .foregroundColor(.lebolTextPrimary)

                Text(subtitle)
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, showLine ? 66 : 0)
        }
    }
}
