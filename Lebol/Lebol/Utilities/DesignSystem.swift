import SwiftUI
import SwiftData
import UIKit

// MARK: - Haptics
enum Haptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func light() { lightGenerator.impactOccurred() }
    static func medium() { mediumGenerator.impactOccurred() }
    static func selection() { selectionGenerator.selectionChanged() }
    static func success() { notificationGenerator.notificationOccurred(.success) }
    static func error() { notificationGenerator.notificationOccurred(.error) }
}

// MARK: - Color Palette
extension Color {
    // Primary teal (brand color)
    static let lebolPrimary = Color(hex: "0DBAB1")
    static let lebolPrimaryLight = Color(hex: "3DD4CB")
    static let lebolPrimaryDark = Color(hex: "099E96")
    static let lebolPrimaryVeryLight = Color(hex: "E6F7F6")

    // Macro colors
    static let lebolCarbs = Color(hex: "D4A574")    // Tan/brown — wheat/grain
    static let lebolProtein = Color(hex: "4A90D9")   // Blue — fish
    static let lebolFats = Color(hex: "4CAF50")       // Green — avocado

    // Neutrals
    static let lebolBackground = Color(hex: "FAFAFA")
    static let lebolSurface = Color(hex: "F8F8F8")
    static let lebolCardBackground = Color.white
    static let lebolTextPrimary = Color(hex: "1A1A1A")
    static let lebolTextSecondary = Color(hex: "9E9E9E")
    static let lebolTextTertiary = Color(hex: "BDBDBD")
    static let lebolDivider = Color(hex: "F0F0F0")
    static let lebolBorder = Color(hex: "E8E8E8")

    // Status
    static let lebolSuccess = Color(hex: "4CAF50")
    static let lebolWarning = Color(hex: "FFC107")
    static let lebolError = Color(hex: "F44336")

    // Water
    static let lebolWater = Color(hex: "42A5F5")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct LebolFont {
    static func largeTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title2() -> Font { .system(size: 22, weight: .bold, design: .rounded) }
    static func title3() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 17, weight: .regular, design: .rounded) }
    static func callout() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func subheadline() -> Font { .system(size: 15, weight: .regular, design: .rounded) }
    static func footnote() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
    static func caption() -> Font { .system(size: 12, weight: .regular, design: .rounded) }

    // Special sizes for numbers/metrics
    static func metricLarge() -> Font { .system(size: 56, weight: .bold, design: .rounded) }
    static func metricMedium() -> Font { .system(size: 40, weight: .bold, design: .rounded) }
    static func metricSmall() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
}

// MARK: - Reusable Button Styles
struct LebolPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LebolFont.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(isEnabled ? Color.lebolPrimary : Color.lebolTextTertiary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct LebolSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LebolFont.headline())
            .foregroundColor(.lebolTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.lebolBorder, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Dismiss Toolbar (shared xmark button for sheet editors)

struct LebolDismissToolbar: ViewModifier {
    var placement: ToolbarItemPlacement = .cancellationAction
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: placement) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lebolTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.lebolDivider))
                }
                .accessibilityLabel("Close")
            }
        }
    }
}

extension View {
    func lebolDismissToolbar(placement: ToolbarItemPlacement = .cancellationAction) -> some View {
        modifier(LebolDismissToolbar(placement: placement))
    }
}

struct SelectionCard: View {
    var symbolName: String? = nil
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 14) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .lebolPrimary : .lebolTextSecondary)
                        .frame(width: 40, height: 40)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(LebolFont.headline())
                        .foregroundColor(.lebolTextPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.lebolTextPrimary : Color.lebolBorder, lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle()
                            .fill(Color.lebolTextPrimary)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? Color.lebolSurface : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.lebolTextPrimary : Color.lebolBorder, lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Card (teal checkmark + title + subtitle)

struct InfoCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.lebolPrimary)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LebolFont.headline())
                Text(subtitle)
                    .font(LebolFont.subheadline())
                    .foregroundColor(.lebolTextSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.lebolSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.lebolBorder, lineWidth: 1)
                )
        )
    }
}

struct OnboardingProgressBar: View {
    let sections: [String]
    let currentSectionIndex: Int
    let progressInSection: Double

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<sections.count, id: \.self) { index in
                if index < currentSectionIndex {
                    // Completed section — primary-accent checkmark circle
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.lebolPrimary)
                        .font(.system(size: 22))
                }

                if index == currentSectionIndex {
                    // Active section — primary-accent capsule with label and progress
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.lebolPrimary.opacity(0.15))
                                .frame(height: 24)
                            Capsule()
                                .fill(Color.lebolPrimary)
                                .frame(width: max(geo.size.width * progressInSection, 60), height: 24)
                            Text(sections[index])
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.leading, 12)
                        }
                    }
                    .frame(height: 24)
                } else if index > currentSectionIndex {
                    // Future section — light gray capsule
                    Capsule()
                        .fill(Color.lebolBorder)
                        .frame(height: 24)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var trackColor: Color = Color.lebolDivider
    var progressColor: Color = Color.lebolPrimary

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(min(progress, 1.0) * 100)) percent")
    }
}

struct LebolTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(LebolFont.body())
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lebolSurface)
            )
    }
}

extension View {
    func lebolTextFieldStyle() -> some View {
        modifier(LebolTextFieldStyle())
    }
}

// MARK: - Macro Icons

enum MacroIcon {
    @ViewBuilder static func calories(size: CGFloat = 16) -> some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size))
            .foregroundColor(.orange)
    }

    @ViewBuilder static func carbs(size: CGFloat = 26) -> some View {
        Image("icon-wheat")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: size)
            .foregroundColor(.lebolCarbs)
    }

    @ViewBuilder static func protein(size: CGFloat = 16) -> some View {
        Image(systemName: "fish.fill")
            .font(.system(size: size))
            .foregroundColor(.lebolProtein)
    }

    @ViewBuilder static func fats(size: CGFloat = 26) -> some View {
        Image("icon-avocado")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: size)
            .foregroundColor(.lebolFats)
    }
}

// MARK: - ModelContext Save with Logging

extension ModelContext {
    func saveWithLogging(file: String = #file, line: Int = #line) {
        do {
            try save()
        } catch {
            print("[\(URL(fileURLWithPath: file).lastPathComponent):\(line)] SwiftData save failed: \(error)")
        }
    }
}
