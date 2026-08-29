import SwiftUI

// MARK: - Measurement System Toggle (shared by HeightPicker and WeightPicker)

struct MeasurementSystemToggle: View {
    @Binding var useMetric: Bool
    let metricLabel: String
    let imperialLabel: String

    var body: some View {
        HStack(spacing: 0) {
            Button {
                useMetric = true
            } label: {
                Text(metricLabel)
                    .font(LebolFont.headline())
                    .foregroundColor(useMetric ? .lebolTextPrimary : .lebolTextSecondary)
                    .frame(width: 64, height: 40)
                    .background(useMetric ? Color.white : Color.clear)
                    .cornerRadius(18)
            }

            Button {
                useMetric = false
            } label: {
                Text(imperialLabel)
                    .font(LebolFont.headline())
                    .foregroundColor(!useMetric ? .lebolTextPrimary : .lebolTextSecondary)
                    .frame(width: 64, height: 40)
                    .background(!useMetric ? Color.white : Color.clear)
                    .cornerRadius(18)
            }
        }
        .padding(3)
        .background(Color.lebolDivider)
        .cornerRadius(20)
    }
}

// MARK: - Shared Height Picker (used by HeightStepView and ProfileHeightEditor)

struct HeightPicker: View {
    @Binding var heightCm: Double
    @Binding var useMetric: Bool
    var showMeasurementSystemToggle: Bool = true

    private var displayFeet: Int {
        let totalInches = heightCm / 2.54
        return Int(totalInches) / 12
    }

    private var displayInches: Int {
        let totalInches = heightCm / 2.54
        return Int(totalInches.rounded()) % 12
    }

    var body: some View {
        VStack(spacing: 0) {
            // Measurement system toggle at top (hidden in profile editors)
            if showMeasurementSystemToggle {
                MeasurementSystemToggle(useMetric: $useMetric, metricLabel: "cm", imperialLabel: "ft")
                    .padding(.top, 16)
            }

            // Ruler + value display + indicator
            ZStack {
                // Ruler on far left
                HStack {
                    if useMetric {
                        VerticalRulerCm(
                            value: $heightCm,
                            minValue: 120,
                            maxValue: 220
                        )
                        .frame(width: 80)
                    } else {
                        VerticalRulerFt(
                            valueCm: $heightCm,
                            minCm: 120,
                            maxCm: 220
                        )
                        .frame(width: 80)
                    }
                    Spacer()
                }

                // Value display centered on screen
                if useMetric {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(heightCm))")
                            .font(LebolFont.metricLarge())
                            .foregroundColor(.lebolTextPrimary)
                        Text("cm")
                            .font(LebolFont.title2())
                            .foregroundColor(.lebolTextSecondary)
                    }
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text("\(displayFeet)")
                            .font(LebolFont.metricLarge())
                            .foregroundColor(.lebolTextPrimary)
                        Text("'")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.lebolTextSecondary)
                        Text("\(displayInches)")
                            .font(LebolFont.metricLarge())
                            .foregroundColor(.lebolTextPrimary)
                        Text("\"")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.lebolTextSecondary)
                        Text("ft")
                            .font(LebolFont.title2())
                            .foregroundColor(.lebolTextSecondary)
                            .padding(.leading, 3)
                    }
                }

                // Indicator line across ruler (vertically centered)
                HStack {
                    Rectangle()
                        .fill(Color.lebolPrimary)
                        .frame(width: 90, height: 2)
                    Spacer()
                }
            }
        }
        .frame(height: 360)
    }
}

// MARK: - Shared Weight Picker (used by WeightStepView, ProfileWeightEditor, and as base for TargetWeightPicker)

struct WeightPicker: View {
    @Binding var weightKg: Double
    @Binding var useMetric: Bool
    var minValue: Double = 40
    var maxValue: Double = 200
    var showMeasurementSystemToggle: Bool = true
    // Target-weight mode options (defaults preserve standard weight picker behavior)
    var referenceWeightKg: Double? = nil
    var showWarningZone: Bool = false
    var snapStep: Double = 0.1

    private var displayValue: String {
        LebolFormatters.formatWeightPickerValue(weightKg, useMetric: useMetric)
    }

    private var unitLabel: String {
        useMetric ? "kg" : "lbs"
    }

    private func displayReference(_ refKg: Double) -> String {
        if useMetric {
            return String(format: "%.1f", refKg)
        } else {
            return String(format: "%.1f", refKg * NutritionCalculator.kgToLbs)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Measurement system toggle (hidden in profile editors)
            if showMeasurementSystemToggle {
                MeasurementSystemToggle(useMetric: $useMetric, metricLabel: "kg", imperialLabel: "lbs")
                    .padding(.top, 16)
            }

            Spacer()

            // Weight display (with optional reference weight for target-weight mode)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(displayValue)
                    .font(LebolFont.metricLarge())
                    .foregroundColor(.lebolTextPrimary)
                Text(unitLabel)
                    .font(LebolFont.title2())
                    .foregroundColor(.lebolTextSecondary)

                if let refKg = referenceWeightKg {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward.2")
                            .font(LebolFont.caption())
                        Text(displayReference(refKg))
                            .font(LebolFont.title3())
                    }
                    .foregroundColor(.lebolTextTertiary)
                }
            }

            Spacer().frame(height: 24)

            // Horizontal ruler - adapts to measurement system
            ZStack {
                if useMetric {
                    HorizontalRulerKg(
                        value: $weightKg,
                        minValue: minValue,
                        maxValue: maxValue,
                        showWarningZone: showWarningZone,
                        snapStep: snapStep
                    )
                    .frame(height: 80)
                } else {
                    HorizontalRulerLbs(
                        valueKg: $weightKg,
                        minKg: minValue,
                        maxKg: maxValue,
                        showWarningZone: showWarningZone,
                        snapStep: snapStep
                    )
                    .frame(height: 80)
                }

                // Center indicator line
                Rectangle()
                    .fill(Color.lebolPrimary)
                    .frame(width: 2, height: 60)
            }

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight")
        .accessibilityValue("\(displayValue) \(unitLabel)")
        .accessibilityAdjustableAction { direction in
            let step = snapStep
            switch direction {
            case .increment:
                weightKg = min(weightKg + step, maxValue)
            case .decrement:
                weightKg = max(weightKg - step, minValue)
            @unknown default: break
            }
        }
    }
}

// MARK: - Shared Target Weight Picker (thin wrapper over WeightPicker with warning zone + reference)

struct TargetWeightPicker: View {
    @Binding var targetWeightKg: Double
    @Binding var useMetric: Bool
    let currentWeightKg: Double
    var showMeasurementSystemToggle: Bool = true

    var body: some View {
        WeightPicker(
            weightKg: $targetWeightKg,
            useMetric: $useMetric,
            minValue: 40,
            maxValue: currentWeightKg,
            showMeasurementSystemToggle: showMeasurementSystemToggle,
            referenceWeightKg: currentWeightKg,
            showWarningZone: true
        )
    }
}

// MARK: - Healthy Target Info Card (shared by TargetWeightStepView and ProfileTargetWeightEditor)

struct HealthyTargetInfoCard: View {
    let heightCm: Double
    let useMetric: Bool

    private var healthyTargetKg: Double {
        NutritionCalculator.recommendedTargetWeight(heightCm: heightCm)
    }

    private var healthyTargetNote: String {
        if useMetric {
            return String(format: "A healthy target is about %.0f kg", healthyTargetKg)
        } else {
            return String(format: "A healthy target is about %.0f lbs", healthyTargetKg * NutritionCalculator.kgToLbs)
        }
    }

    var body: some View {
        InfoCard(
            title: healthyTargetNote,
            subtitle: "This puts you in a healthy BMI range. It can boost your energy and lower health risks"
        )
    }
}

// MARK: - Shared Pace Slider (used by PaceStepView and ProfileWeeklyGoalEditor)

struct PaceSlider: View {
    @Binding var goalGrams: Int
    var minGrams: Double = 100
    var maxGrams: Double = 1000

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let sliderRange = maxGrams - minGrams
                let progress = (Double(goalGrams) - minGrams) / sliderRange
                let clampedProgress = min(max(progress, 0), 1)
                let thumbX = clampedProgress * (geo.size.width - 28) + 14

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.lebolDivider)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.lebolPrimary)
                        .frame(width: max(0, thumbX), height: 6)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.lebolPrimary, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .position(x: thumbX, y: 14)
                }
                .frame(height: 28)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let fraction = (drag.location.x - 14) / (geo.size.width - 28)
                            let clamped = min(max(fraction, 0), 1)
                            let grams = minGrams + clamped * sliderRange
                            // Snap to nearest 100g (0.1 kg discrete steps)
                            goalGrams = Int((grams / 100).rounded()) * 100
                            goalGrams = min(max(goalGrams, Int(minGrams)), Int(maxGrams))
                        }
                )
            }
            .frame(height: 28)
            .padding(.horizontal, 20)

            HStack {
                Text("Easy")
                    .foregroundColor(.lebolTextSecondary)
                Spacer()
                Text("Balanced")
                    .foregroundColor(.lebolTextSecondary)
                Spacer()
                Text("Strict")
                    .foregroundColor(.lebolTextSecondary)
            }
            .font(LebolFont.footnote())
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly goal pace")
        .accessibilityValue("\(Double(goalGrams) / 1000.0, specifier: "%.1f") kilograms per week")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                goalGrams = min(goalGrams + 100, Int(maxGrams))
            case .decrement:
                goalGrams = max(goalGrams - 100, Int(minGrams))
            @unknown default: break
            }
        }
    }
}

// MARK: - Generic Horizontal Ruler (parameterized Canvas + DragGesture)

struct HorizontalRuler: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let pixelsPerUnit: CGFloat
    let tickStep: Double
    let majorTickEvery: Int
    let midTickEvery: Int?
    let snapStep: Double
    var showWarningZone: Bool = false

    @State private var lastDragValue: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            Canvas { context, size in
                // Warning zone (right of center = above target weight)
                if showWarningZone {
                    let zoneStartX = centerX + 2
                    if zoneStartX < size.width {
                        let zonePath = Path { p in
                            p.addRect(CGRect(x: zoneStartX, y: 28, width: size.width - zoneStartX, height: 40))
                        }
                        context.fill(zonePath, with: .color(Color.lebolWarning.opacity(0.15)))
                    }
                }

                let tickColor = Color.lebolTextSecondary.opacity(0.45)
                // Generate ticks at clean multiples of tickStep (from 0) to avoid
                // floating-point drift when minValue isn't a clean multiple (e.g., lbs)
                let firstTickIndex = Int(ceil(minValue / tickStep))
                // Extend ticks beyond maxValue when warning zone is active so the zone has visual context
                let visualMax = showWarningZone ? maxValue + 10 : maxValue
                let lastTickIndex = Int(floor(visualMax / tickStep))

                for i in firstTickIndex...lastTickIndex {
                    let tickValue = Double(i) * tickStep
                    let x = centerX + CGFloat(tickValue - value) * pixelsPerUnit

                    guard x > -10 && x < size.width + 10 else { continue }

                    let intVal = Int(tickValue.rounded())
                    let distToWhole = abs(tickValue - Double(intVal))
                    let isWhole = distToWhole < 0.01
                    let isMajor = isWhole && intVal % majorTickEvery == 0
                    let isMid: Bool = {
                        guard let midEvery = midTickEvery else { return false }
                        return isWhole && intVal % midEvery == 0
                    }()

                    // Check for 0.5 half-mark between whole numbers
                    let fractPart = tickValue - floor(tickValue)
                    let isHalf = !isWhole && abs(fractPart - 0.5) < 0.01

                    // All ticks bottom-aligned at y=68, growing upward
                    let bottom: CGFloat = 68

                    if isMajor {
                        // Label above ticks
                        let text = Text("\(intVal)")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Color.lebolTextSecondary)
                        context.draw(context.resolve(text), at: CGPoint(x: x, y: 12), anchor: .center)

                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: x, y: 28))
                            p.addLine(to: CGPoint(x: x, y: bottom))
                        }
                        context.stroke(tickPath, with: .color(tickColor), lineWidth: 1.5)
                    } else if isMid || isHalf {
                        // Medium tick at 0.5 marks or midTickEvery
                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: x, y: 44))
                            p.addLine(to: CGPoint(x: x, y: bottom))
                        }
                        context.stroke(tickPath, with: .color(tickColor), lineWidth: 1)
                    } else {
                        // Minor ticks (0.1 intervals)
                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: x, y: 54))
                            p.addLine(to: CGPoint(x: x, y: bottom))
                        }
                        context.stroke(tickPath, with: .color(tickColor), lineWidth: 0.75)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { drag in
                        let delta = drag.translation.width - lastDragValue
                        lastDragValue = drag.translation.width
                        let unitDelta = Double(-delta) / Double(pixelsPerUnit)
                        let newValue = value + unitDelta
                        let snapped = (newValue / snapStep).rounded() * snapStep
                        value = min(max(snapped, minValue), maxValue)
                    }
                    .onEnded { _ in
                        lastDragValue = 0
                        value = (value / snapStep).rounded() * snapStep
                    }
            )
        }
    }
}

// MARK: - Generic Vertical Ruler (parameterized Canvas + DragGesture)

struct VerticalRuler: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let pixelsPerUnit: CGFloat
    let majorTickTest: (Int) -> Bool
    let midTickTest: ((Int) -> Bool)?
    let labelFormatter: (Int) -> String
    var snapStep: Double = 1.0

    @State private var lastDragValue: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let centerY = geo.size.height / 2

            Canvas { context, size in
                let minI = Int(minValue)
                let maxI = Int(maxValue)
                let tickColor = Color.lebolTextSecondary.opacity(0.45)

                for i in minI...maxI {
                    let y = centerY + CGFloat(Double(i) - value) * pixelsPerUnit * -1

                    guard y > -20 && y < size.height + 20 else { continue }

                    let isMajor = majorTickTest(i)
                    let isMid = midTickTest?(i) ?? false

                    // All ticks left-aligned, labels on right
                    // Lengths match horizontal ruler: major=40, mid=24, minor=14
                    if isMajor {
                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: 40, y: y))
                        }
                        context.stroke(tickPath, with: .color(tickColor), lineWidth: 1.5)

                        let text = Text(labelFormatter(i))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Color.lebolTextSecondary)
                        context.draw(context.resolve(text), at: CGPoint(x: 46, y: y), anchor: .leading)
                    } else if isMid {
                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: 24, y: y))
                        }
                        context.stroke(tickPath, with: .color(tickColor), lineWidth: 1)
                    } else {
                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: 14, y: y))
                        }
                        context.stroke(tickPath, with: .color(tickColor), lineWidth: 0.75)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { drag in
                        let delta = drag.translation.height - lastDragValue
                        lastDragValue = drag.translation.height
                        let unitDelta = Double(delta) / Double(pixelsPerUnit)
                        let newValue = value + unitDelta
                        let snapped = (newValue / snapStep).rounded() * snapStep
                        value = min(max(snapped, minValue), maxValue)
                    }
                    .onEnded { _ in
                        lastDragValue = 0
                        value = (value / snapStep).rounded() * snapStep
                    }
            )
        }
    }
}

// MARK: - Custom Age Scroll Picker

struct AgeScrollPicker: View {
    @Binding var selectedAge: Int
    let minAge: Int
    let maxAge: Int

    private let itemHeight: CGFloat = 60
    private let visibleItems = 5

    @State private var dragOffset: CGFloat = 0

    private var totalOffset: CGFloat {
        -CGFloat(selectedAge - minAge) * itemHeight + dragOffset
    }

    var body: some View {
        GeometryReader { geo in
            let centerY = geo.size.height / 2

            ZStack {
                // Selected item background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.lebolDivider)
                    .frame(width: geo.size.width * 0.75, height: itemHeight)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    .position(x: geo.size.width / 2, y: centerY)

                // Age items
                ForEach(minAge...maxAge, id: \.self) { age in
                    let offset = CGFloat(age - minAge) * itemHeight + totalOffset
                    let y = centerY + offset
                    let distanceFromCenter = abs(y - centerY)
                    let maxDistance = CGFloat(visibleItems / 2 + 1) * itemHeight
                    let opacity = max(0, 1 - (distanceFromCenter / maxDistance))
                    let scale = max(0.6, 1 - (distanceFromCenter / maxDistance) * 0.4)

                    if distanceFromCenter < maxDistance {
                        Text("\(age)")
                            .font(.system(size: age == selectedAge ? 40 : 28, weight: age == selectedAge ? .bold : .regular, design: .rounded))
                            .foregroundColor(age == selectedAge ? .lebolTextPrimary : .lebolTextSecondary)
                            .position(x: geo.size.width / 2, y: y)
                            .opacity(opacity)
                            .scaleEffect(scale)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { drag in
                        dragOffset = drag.translation.height
                    }
                    .onEnded { drag in
                        let offsetInItems = -drag.translation.height / itemHeight
                        let newAge = selectedAge + Int(offsetInItems.rounded())
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedAge = min(max(newAge, minAge), maxAge)
                            dragOffset = 0
                        }
                    }
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Age")
        .accessibilityValue("\(selectedAge) years")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                selectedAge = min(selectedAge + 1, maxAge)
            case .decrement:
                selectedAge = max(selectedAge - 1, minAge)
            @unknown default: break
            }
        }
    }
}
