import Foundation

enum LebolFormatters {
    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    /// "95,0 kg" or "209 lbs"
    static func formatWeight(_ kg: Double, useMetric: Bool) -> String {
        if useMetric {
            return "\(decimalFormatter.string(from: NSNumber(value: kg)) ?? String(format: "%.1f", kg)) kg"
        } else {
            return "\(Int(round(kg * NutritionCalculator.kgToLbs))) lbs"
        }
    }

    /// "95,0" or "209" — number only, no unit
    static func formatWeightValue(_ kg: Double, useMetric: Bool) -> String {
        if useMetric {
            return decimalFormatter.string(from: NSNumber(value: kg)) ?? String(format: "%.1f", kg)
        } else {
            return "\(Int(round(kg * NutritionCalculator.kgToLbs)))"
        }
    }

    /// Formats weight value for picker display (shows integer when near whole number)
    static func formatWeightPickerValue(_ kg: Double, useMetric: Bool) -> String {
        let value = useMetric ? kg : kg * NutritionCalculator.kgToLbs
        let rounded = (value * 10).rounded() / 10
        let remainder = rounded.truncatingRemainder(dividingBy: 1)
        if remainder < 0.05 || remainder > 0.95 {
            return "\(Int(rounded.rounded()))"
        }
        if useMetric {
            return decimalFormatter.string(from: NSNumber(value: rounded)) ?? String(format: "%.1f", rounded)
        } else {
            return String(format: "%.1f", rounded)
        }
    }

    /// "800 g per week" or "1,8 lbs per week"
    static func formatWeeklyGoal(_ grams: Int, useMetric: Bool) -> String {
        if useMetric {
            return "\(grams) g per week"
        } else {
            let lbs = Double(grams) / 1000.0 * NutritionCalculator.kgToLbs
            return "\(decimalFormatter.string(from: NSNumber(value: lbs)) ?? String(format: "%.1f", lbs)) lbs per week"
        }
    }

    /// "0,8" or "1,8" — rate number only for pace display
    static func formatWeeklyRate(_ kg: Double, useMetric: Bool) -> String {
        let value = useMetric ? kg : kg * NutritionCalculator.kgToLbs
        return decimalFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    /// "1 m, 76 cm" or "5′9″"
    static func formatHeight(_ cm: Double, useMetric: Bool) -> String {
        if useMetric {
            let meters = Int(cm) / 100
            let remainder = Int(cm) % 100
            return "\(meters) m, \(remainder) cm"
        } else {
            let totalInches = cm / 2.54
            let feet = Int(totalInches) / 12
            let inches = Int(totalInches) % 12
            return "\(feet)'\(inches)\" ft"
        }
    }
}
