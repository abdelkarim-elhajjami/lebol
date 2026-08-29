import SwiftUI
import SwiftData

struct NutritionDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @Binding var showingAddSheet: Bool
    @Binding var selectedDate: Date
    @Bindable var authViewModel: AuthViewModel
    @State private var showingProfile = false
    @State private var showingMealDetail: MealType?
    @State private var showingMealLogSheet: MealType?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    var body: some View {
        Group {
            if let viewModel {
                dashboardContent(viewModel)
            } else {
                Color.lebolBackground
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DashboardViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func dashboardContent(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView(vm)

                calorieRingCard(vm)

                mealSlotsSection(vm)

                waterSection(vm)

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.lebolBackground)
        .refreshable {
            vm.reloadData()
        }
        .onChange(of: vm.selectedDate) {
            selectedDate = vm.selectedDate
            vm.reloadData()
        }
        .onChange(of: selectedDate) {
            if vm.selectedDate != selectedDate {
                vm.selectedDate = selectedDate
                vm.reloadData()
            }
        }
        .sheet(isPresented: $showingProfile, onDismiss: { vm.reloadData() }) {
            ProfileSheetView(authViewModel: authViewModel)
        }
        .sheet(item: $showingMealDetail, onDismiss: { vm.reloadData() }) { type in
            MealDetailView(
                mealType: type,
                meals: Binding(
                    get: { vm.todayLog?.meals ?? [] },
                    set: { _ in }
                ),
                dailyLog: vm.todayLog,
                logDate: vm.selectedDate
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $showingMealLogSheet, onDismiss: { vm.reloadData() }) { type in
            AddActionSheet(fixedMealType: type, logDate: vm.selectedDate)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.lebolBackground)
        }
    }

    private func handleMealSlotTap(_ type: MealType, hasMeals: Bool) {
        if hasMeals {
            showingMealDetail = type
        } else {
            showingMealLogSheet = type
        }
    }

    private func isToday(_ vm: DashboardViewModel) -> Bool {
        Calendar.current.isDateInToday(vm.selectedDate)
    }

    private func dateLabel(_ vm: DashboardViewModel) -> String {
        if isToday(vm) { return "Today" }
        if Calendar.current.isDateInYesterday(vm.selectedDate) { return "Yesterday" }
        return Self.dateFormatter.string(from: vm.selectedDate)
    }

    // MARK: - Header
    private func headerView(_ vm: DashboardViewModel) -> some View {
        let today = isToday(vm)
        return HStack(alignment: .center) {
            Button {
                vm.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: vm.selectedDate) ?? vm.selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lebolTextSecondary)
                    .frame(width: 32, height: 32)
            }

            VStack(spacing: 2) {
                Text(dateLabel(vm))
                    .font(LebolFont.headline())
                    .foregroundColor(.lebolTextPrimary)
                Text(Self.dateFormatter.string(from: vm.selectedDate))
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextSecondary)
            }
            .onTapGesture {
                vm.selectedDate = Date()
            }

            Button {
                guard !today else { return }
                vm.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: vm.selectedDate) ?? vm.selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(today ? .lebolTextTertiary : .lebolTextSecondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(today)

            Spacer()

            // Streak badge
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.lebolPrimary)
                Text("\(vm.streak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.lebolTextPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(Color.lebolBorder, lineWidth: 1)
            )

            // Profile
            Button {
                showingProfile = true
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.lebolTextPrimary)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Calorie Ring + Macros Card
    private func calorieRingCard(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                // Eaten
                VStack(spacing: 6) {
                    Text("\(vm.caloriesEaten)")
                        .font(LebolFont.title3())
                        .foregroundColor(.lebolTextPrimary)
                    Text("Eaten")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }
                .frame(width: 70)

                Spacer()

                // Ring
                ZStack {
                    CircularProgressView(
                        progress: vm.calorieProgress,
                        lineWidth: 8,
                        size: 180,
                        trackColor: Color.lebolDivider,
                        progressColor: Color.lebolPrimary
                    )

                    VStack(spacing: 4) {
                        Text("\(vm.caloriesLeft)")
                            .font(LebolFont.metricMedium())
                            .foregroundColor(.lebolTextPrimary)
                        Text("kcal left")
                            .font(LebolFont.footnote())
                            .foregroundColor(.lebolTextSecondary)
                    }
                }

                Spacer()

                // Burned
                VStack(spacing: 6) {
                    Text("\(vm.caloriesBurned)")
                        .font(LebolFont.title3())
                        .foregroundColor(.lebolTextPrimary)
                    Text("Burned")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }
                .frame(width: 70)
            }

            // Macros inside the same card
            macroSection(vm)
        }
        .padding(20)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: - Macros
    private func macroSection(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: 0) {
            macroItem(
                icon: MacroIcon.carbs(size: 16),
                label: "Carbs",
                current: vm.carbsEaten,
                target: vm.carbsTarget
            )

            macroItem(
                icon: MacroIcon.protein(size: 14),
                label: "Protein",
                current: vm.proteinEaten,
                target: vm.proteinTarget
            )

            macroItem(
                icon: MacroIcon.fats(size: 16),
                label: "Fats",
                current: vm.fatsEaten,
                target: vm.fatsTarget
            )
        }
    }

    private func macroItem(icon: some View, label: String, current: Double, target: Double) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                icon
                Text(label)
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextSecondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.lebolDivider)
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.lebolPrimary)
                        .frame(width: geo.size.width * min(target > 0 ? current / target : 0, 1.0), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 8)

            Text("\(Int(current)) / \(Int(target))")
                .font(LebolFont.footnote().weight(.medium))
                .foregroundColor(.lebolTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Meal Slots
    private func mealSlotsSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife")
                    .font(.system(size: 14))
                    .foregroundColor(.lebolPrimary)
                Text("Nutrition")
                    .font(LebolFont.headline())
                Spacer()
            }

            HStack(spacing: 8) {
                MealSlotButton(type: .breakfast, calories: vm.calories(for: .breakfast), hasMeals: !vm.meals(for: .breakfast).isEmpty) {
                    handleMealSlotTap(.breakfast, hasMeals: !vm.meals(for: .breakfast).isEmpty)
                }
                MealSlotButton(type: .lunch, calories: vm.calories(for: .lunch), hasMeals: !vm.meals(for: .lunch).isEmpty) {
                    handleMealSlotTap(.lunch, hasMeals: !vm.meals(for: .lunch).isEmpty)
                }
                MealSlotButton(type: .dinner, calories: vm.calories(for: .dinner), hasMeals: !vm.meals(for: .dinner).isEmpty) {
                    handleMealSlotTap(.dinner, hasMeals: !vm.meals(for: .dinner).isEmpty)
                }
                MealSlotButton(type: .snack, calories: vm.calories(for: .snack), hasMeals: !vm.meals(for: .snack).isEmpty) {
                    handleMealSlotTap(.snack, hasMeals: !vm.meals(for: .snack).isEmpty)
                }
            }
        }
        .padding(20)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: - Water
    private func waterSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.lebolWater)
                Text("Water")
                    .font(LebolFont.headline())
                Spacer()
                Text("Goal: \(Int(vm.waterGoal)) ml")
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.lebolTextSecondary)
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(vm.waterConsumed))")
                        .font(LebolFont.title2())
                        .foregroundColor(.lebolTextPrimary)
                    Text("ml")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }

                Spacer()

                // Water cups
                HStack(spacing: 4) {
                    ForEach(0..<min(vm.waterGlassesTarget, 8), id: \.self) { index in
                        WaterCupShape()
                            .fill(index < vm.waterGlasses ? Color.lebolWater : Color.lebolDivider)
                            .frame(width: 22, height: 26)
                    }
                }

                Spacer()

                Button {
                    Haptics.light()
                    vm.addWater(amount: 250)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.lebolWater)
                }
            }
        }
        .padding(20)
        .background(Color.lebolCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Meal Slot Button
struct MealSlotButton: View {
    let type: MealType
    let calories: Int
    let hasMeals: Bool
    let action: () -> Void

    private var mealSymbol: String {
        type.symbolName
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Background circle with border
                    Circle()
                        .fill(Color.lebolDivider)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.lebolBorder, lineWidth: 1)
                        )

                    // Progress arc (only when has meals)
                    if hasMeals {
                        Circle()
                            .trim(from: 0, to: min(Double(calories) / 600.0, 1.0))
                            .stroke(Color.lebolPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 60, height: 60)
                    }

                    if hasMeals {
                        // Meal icon when has meals
                        Image(systemName: mealSymbol)
                            .font(.system(size: 20))
                            .foregroundColor(.lebolPrimary)
                    } else {
                        // Centered "+" when no meals
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.lebolTextSecondary)
                    }
                }
                .frame(width: 60, height: 60)

                Text(type.rawValue)
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextPrimary)
                    .lineLimit(1)
                Text("\(calories) kcal")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.lebolTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Water Cup Shape
struct WaterCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset: CGFloat = rect.width * 0.12
        // Trapezoid: wider at top, narrower at bottom
        path.move(to: CGPoint(x: topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.height))
        path.closeSubpath()
        return path
    }
}
