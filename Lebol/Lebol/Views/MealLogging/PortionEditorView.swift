import SwiftUI

// MARK: - Shared Data Struct (eliminates dual-mode branching)

struct PortionData {
    let name: String
    let servingUnit: ServingUnit
    let unitWeight: Double
    let caloriesPer100g: Double
    let carbsPer100g: Double
    let proteinPer100g: Double
    let fatsPer100g: Double
    let initialGrams: Double
    let initialCalories: Double
    let initialCarbs: Double
    let initialProtein: Double
    let initialFats: Double

    init(from item: ReviewableFoodItem) {
        self.name = item.name
        self.servingUnit = item.servingUnit
        self.unitWeight = item.unitWeight
        self.caloriesPer100g = item.caloriesPer100g
        self.carbsPer100g = item.carbsPer100g
        self.proteinPer100g = item.proteinPer100g
        self.fatsPer100g = item.fatsPer100g
        self.initialGrams = item.servingGrams
        self.initialCalories = item.calories
        self.initialCarbs = item.carbs
        self.initialProtein = item.protein
        self.initialFats = item.fats
    }

    init(from food: FoodItem) {
        self.name = food.name
        self.servingUnit = food.servingUnit
        self.unitWeight = food.unitWeight
        self.caloriesPer100g = food.caloriesPer100g
        self.carbsPer100g = food.carbsPer100g
        self.proteinPer100g = food.proteinPer100g
        self.fatsPer100g = food.fatsPer100g
        self.initialGrams = food.servingGrams
        self.initialCalories = food.calories
        self.initialCarbs = food.carbs
        self.initialProtein = food.protein
        self.initialFats = food.fats
    }
}

// MARK: - Portion Editor Result

struct PortionResult {
    let grams: Double
    let sizeLabel: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fats: Double
}

// MARK: - PortionEditorView

struct PortionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let data: PortionData
    private let onSave: (PortionResult) -> Void

    @State private var quantityText: String
    @State private var currentGrams: Double

    // MARK: - Init for ReviewableFoodItem (convenience)

    init(item: Binding<ReviewableFoodItem>) {
        let d = PortionData(from: item.wrappedValue)
        self.data = d
        let binding = item
        self.onSave = { result in
            binding.wrappedValue.servingGrams = result.grams
            binding.wrappedValue.servingSize = result.sizeLabel
            binding.wrappedValue.calories = result.calories
            binding.wrappedValue.carbs = result.carbs
            binding.wrappedValue.protein = result.protein
            binding.wrappedValue.fats = result.fats
        }
        self._currentGrams = State(initialValue: d.initialGrams)
        let displayQty = Self.displayQuantity(grams: d.initialGrams, unit: d.servingUnit, unitWeight: d.unitWeight)
        self._quantityText = State(initialValue: Self.formatQuantity(displayQty, unit: d.servingUnit))
    }

    // MARK: - Init for FoodItem (convenience)

    init(food: FoodItem, onUpdate: @escaping (FoodItem) -> Void) {
        let d = PortionData(from: food)
        self.data = d
        self.onSave = { result in
            food.servingGrams = result.grams
            food.servingSize = result.sizeLabel
            food.calories = result.calories
            food.carbs = result.carbs
            food.protein = result.protein
            food.fats = result.fats
            onUpdate(food)
        }
        self._currentGrams = State(initialValue: d.initialGrams)
        let displayQty = Self.displayQuantity(grams: d.initialGrams, unit: d.servingUnit, unitWeight: d.unitWeight)
        self._quantityText = State(initialValue: Self.formatQuantity(displayQty, unit: d.servingUnit))
    }

    // MARK: - Unit Helpers

    private static func displayQuantity(grams: Double, unit: ServingUnit, unitWeight: Double) -> Double {
        switch unit {
        case .pieces where unitWeight > 0: return grams / unitWeight
        default: return grams
        }
    }

    private static func formatQuantity(_ qty: Double, unit: ServingUnit) -> String {
        if unit == .pieces {
            return qty.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(qty))" : String(format: "%.1f", qty)
        }
        return "\(Int(qty))"
    }

    private var currentDisplayQuantity: Double {
        Self.displayQuantity(grams: currentGrams, unit: data.servingUnit, unitWeight: data.unitWeight)
    }

    private var unitLabel: String {
        switch data.servingUnit {
        case .milliliters: return "ml"
        case .pieces: return "pcs"
        case .grams: return "g"
        }
    }

    private var stepDelta: Double {
        switch data.servingUnit {
        case .milliliters: return 50
        case .pieces where data.unitWeight > 0: return data.unitWeight * 0.5
        default: return 10
        }
    }

    private var presets: [Double] {
        switch data.servingUnit {
        case .milliliters: return [100, 150, 200, 250, 330]
        case .pieces: return [1, 2, 3, 4, 5]
        case .grams: return [50, 100, 150, 200, 250]
        }
    }

    private var per100gAvailable: Bool { data.caloriesPer100g > 0 }

    // Calculated preview values (guard against division by zero when initialGrams == 0)
    private var previewCalories: Double {
        if per100gAvailable { return data.caloriesPer100g * currentGrams / 100 }
        guard data.initialGrams > 0 else { return data.initialCalories }
        return data.initialCalories * currentGrams / data.initialGrams
    }
    private var previewCarbs: Double {
        if per100gAvailable { return data.carbsPer100g * currentGrams / 100 }
        guard data.initialGrams > 0 else { return data.initialCarbs }
        return data.initialCarbs * currentGrams / data.initialGrams
    }
    private var previewProtein: Double {
        if per100gAvailable { return data.proteinPer100g * currentGrams / 100 }
        guard data.initialGrams > 0 else { return data.initialProtein }
        return data.initialProtein * currentGrams / data.initialGrams
    }
    private var previewFats: Double {
        if per100gAvailable { return data.fatsPer100g * currentGrams / 100 }
        guard data.initialGrams > 0 else { return data.initialFats }
        return data.initialFats * currentGrams / data.initialGrams
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Food name
                Text(data.name)
                    .font(LebolFont.title3())
                    .foregroundColor(.lebolTextPrimary)
                    .padding(.top, 16)

                // Portion input
                VStack(spacing: 12) {
                    Text("Portion size")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)

                    HStack(spacing: 16) {
                        Button {
                            adjustQuantity(-stepDelta)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.lebolPrimary)
                        }

                        HStack(spacing: 4) {
                            TextField("0", text: $quantityText)
                                .font(LebolFont.metricSmall())
                                .foregroundColor(.lebolTextPrimary)
                                .keyboardType(data.servingUnit == .pieces ? .decimalPad : .numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .onChange(of: quantityText) { _, newValue in
                                    if let val = Double(newValue), val > 0 {
                                        updateGramsFromDisplay(val)
                                    }
                                }
                            Text(unitLabel)
                                .font(LebolFont.title3())
                                .foregroundColor(.lebolTextSecondary)
                        }

                        Button {
                            adjustQuantity(stepDelta)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.lebolPrimary)
                        }
                    }

                    // Quick presets
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            let presetGrams = data.servingUnit == .pieces && data.unitWeight > 0 ? preset * data.unitWeight : preset
                            let isSelected: Bool = {
                                if data.servingUnit == .pieces { return abs(currentDisplayQuantity - preset) < 0.01 }
                                return abs(currentGrams - preset) < 0.01
                            }()
                            Button {
                                currentGrams = presetGrams
                                quantityText = Self.formatQuantity(preset, unit: data.servingUnit)
                            } label: {
                                Text(data.servingUnit == .pieces ? "\(Self.formatQuantity(preset, unit: .pieces))" : "\(Int(preset))\(unitLabel)")
                                    .font(LebolFont.caption())
                                    .foregroundColor(isSelected ? .white : .lebolTextSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.lebolPrimary : Color.lebolSurface)
                                    )
                            }
                        }
                    }
                }

                // Live macro preview
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        MacroIcon.calories(size: 18)
                        Text("\(Int(previewCalories))")
                            .font(LebolFont.title2())
                            .foregroundColor(.lebolTextPrimary)
                        Text("calories")
                            .font(LebolFont.body())
                            .foregroundColor(.lebolTextSecondary)
                    }

                    HStack(spacing: 16) {
                        macroPreview(label: "Carbs", icon: MacroIcon.carbs(), value: previewCarbs)
                        macroPreview(label: "Protein", icon: MacroIcon.protein(), value: previewProtein)
                        macroPreview(label: "Fat", icon: MacroIcon.fats(), value: previewFats)
                    }
                }
                .padding(16)
                .background(Color.lebolCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lebolBorder, lineWidth: 1)
                )

                Spacer()

                // Update button
                Button {
                    applyChanges()
                } label: {
                    Text("Update")
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .background(Color.lebolBackground)
            .navigationTitle("Edit Portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lebolTextSecondary)
                }
            }
        }
    }

    private func macroPreview(label: String, icon: some View, value: Double) -> some View {
        VStack(spacing: 4) {
            icon
            Text(String(format: "%.1fg", value))
                .font(LebolFont.headline())
                .foregroundColor(.lebolTextPrimary)
            Text(label)
                .font(LebolFont.caption())
                .foregroundColor(.lebolTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func adjustQuantity(_ deltaGrams: Double) {
        let newGrams = max(1, currentGrams + deltaGrams)
        currentGrams = newGrams
        let displayQty = Self.displayQuantity(grams: newGrams, unit: data.servingUnit, unitWeight: data.unitWeight)
        quantityText = Self.formatQuantity(displayQty, unit: data.servingUnit)
    }

    private func updateGramsFromDisplay(_ displayValue: Double) {
        switch data.servingUnit {
        case .pieces where data.unitWeight > 0:
            currentGrams = displayValue * data.unitWeight
        default:
            currentGrams = displayValue
        }
    }

    private func applyChanges() {
        Haptics.success()

        let displayQty = currentDisplayQuantity
        let sizeLabel: String = {
            switch data.servingUnit {
            case .pieces: return "\(Self.formatQuantity(displayQty, unit: .pieces)) pcs"
            case .milliliters: return "\(Int(currentGrams)) ml"
            case .grams: return "\(Int(currentGrams))g"
            }
        }()

        onSave(PortionResult(
            grams: currentGrams,
            sizeLabel: sizeLabel,
            calories: previewCalories,
            carbs: previewCarbs,
            protein: previewProtein,
            fats: previewFats
        ))

        dismiss()
    }
}
