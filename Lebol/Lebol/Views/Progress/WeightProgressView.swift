import SwiftUI
import SwiftData
import Charts

struct WeightProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .forward) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @State private var showingWeightLog = false
    @State private var showingProfile = false
    @Bindable var authViewModel: AuthViewModel

    private var profile: UserProfile? { profiles.first }
    private var useMetric: Bool { profile?.useMetric ?? true }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(alignment: .center) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 22))
                        .foregroundColor(.lebolTextPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(LebolFont.headline())
                            .foregroundColor(.lebolTextPrimary)
                        Text(Self.dateFormatter.string(from: Date()))
                            .font(LebolFont.caption())
                            .foregroundColor(.lebolTextSecondary)
                    }

                    Spacer()

                    // Streak badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.lebolPrimary)
                        Text("\(currentStreak)")
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

                // Weight card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(.lebolPrimary)
                        Text("Weight")
                            .font(LebolFont.headline())
                    }

                    HStack {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formatWeightDisplay(weightEntries.last?.weightKg ?? profile?.weightKg ?? 95))
                                .font(LebolFont.metricMedium())
                            Text(useMetric ? "kg" : "lbs")
                                .font(LebolFont.title3())
                                .foregroundColor(.lebolTextSecondary)
                        }

                        Spacer()

                        Button {
                            showingWeightLog = true
                        } label: {
                            Text("Log Weight")
                                .font(LebolFont.headline())
                                .foregroundColor(.lebolPrimary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .stroke(Color.lebolPrimary, lineWidth: 1.5)
                                )
                        }
                    }
                }
                .padding(20)
                .background(Color.lebolCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)

                // Empty state for weight tracking
                if weightEntries.count <= 1 {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16))
                            .foregroundColor(.lebolPrimary)
                        Text(weightEntries.isEmpty
                            ? "Log your first weight to start tracking progress"
                            : "Log a second weight to see your progress chart")
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.lebolPrimaryVeryLight)
                    )
                }

                // Weight Chart
                if weightEntries.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight Progress")
                            .font(LebolFont.headline())

                        Chart {
                            ForEach(weightEntries) { entry in
                                LineMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Weight", displayWeight(entry.weightKg))
                                )
                                .foregroundStyle(Color.lebolPrimary)
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Weight", displayWeight(entry.weightKg))
                                )
                                .foregroundStyle(Color.lebolPrimary)
                            }

                            if let target = profile?.targetWeightKg {
                                RuleMark(y: .value("Target", displayWeight(target)))
                                    .foregroundStyle(Color.lebolPrimaryLight.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .annotation(position: .top, alignment: .trailing) {
                                        Text("Target: \(Int(displayWeight(target))) \(useMetric ? "kg" : "lbs")")
                                            .font(LebolFont.caption())
                                            .foregroundColor(.lebolPrimaryLight)
                                    }
                            }
                        }
                        .frame(height: 200)
                        .chartYScale(domain: yAxisRange())
                        .chartXScale(domain: xAxisRange())
                        .chartXAxis {
                            AxisMarks(values: uniqueChartDates()) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        Text(date, format: .dateTime.day().month(.abbreviated))
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.lebolCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
                }

                // Weight History List
                if weightEntries.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight History")
                            .font(LebolFont.headline())
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        let reversed = Array(weightEntries.reversed())
                        List {
                            ForEach(Array(reversed.enumerated()), id: \.element.id) { index, entry in
                                let previousEntry: WeightEntry? = index + 1 < reversed.count ? reversed[index + 1] : nil
                                WeightHistoryRow(
                                    entry: entry,
                                    previousEntry: previousEntry,
                                    useMetric: useMetric
                                )
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .listRowSeparator(index < reversed.count - 1 ? .visible : .hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteWeightEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollDisabled(true)
                        .frame(height: CGFloat(reversed.count) * 52)
                    }
                    .background(Color.lebolCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
                }

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.lebolBackground)
        .onAppear {
            currentStreak = DailyLog.currentStreak(in: modelContext)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheetView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showingWeightLog) {
            ProfileWeightEditor(
                title: "Log weight",
                subtitle: "Update your progress",
                initialValue: profile?.weightKg ?? 80,
                initialUseMetric: profile?.useMetric ?? true
            ) { newValue in
                Haptics.success()
                if let profile = profiles.first {
                    DataService.logWeight(newValue, profile: profile, in: modelContext)
                }
            }
        }
    }

    @State private var currentStreak: Int = 0

    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        guard let first = weightEntries.first?.date,
              let last = weightEntries.last?.date else {
            let now = Date()
            return now...now
        }
        let startOfFirst = calendar.startOfDay(for: first)
        let endOfLast = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) ?? last
        // If all on same day, extend range to show full day
        if calendar.isDate(first, inSameDayAs: last) {
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: startOfFirst) ?? startOfFirst
            return dayBefore...endOfLast
        }
        return startOfFirst...endOfLast
    }

    private func uniqueChartDates() -> [Date] {
        let calendar = Calendar.current
        var seen = Set<DateComponents>()
        var dates: [Date] = []
        for entry in weightEntries {
            let components = calendar.dateComponents([.year, .month, .day], from: entry.date)
            if !seen.contains(components) {
                seen.insert(components)
                dates.append(calendar.startOfDay(for: entry.date))
            }
        }
        // If too many dates, show evenly spaced subset
        if dates.count > 7 {
            let step = max(1, dates.count / 5)
            var subset: [Date] = []
            for i in stride(from: 0, to: dates.count, by: step) {
                subset.append(dates[i])
            }
            if let last = dates.last, subset.last != last { subset.append(last) }
            return subset
        }
        return dates
    }

    private func displayWeight(_ kg: Double) -> Double {
        useMetric ? kg : kg * NutritionCalculator.kgToLbs
    }

    private func formatWeightDisplay(_ kg: Double) -> String {
        LebolFormatters.formatWeightValue(kg, useMetric: useMetric)
    }

    private func deleteWeightEntry(_ entry: WeightEntry) {
        Haptics.error()
        // Capture latest remaining entry BEFORE deletion to avoid race with @Query
        let latestRemaining = weightEntries.filter { $0.id != entry.id }.last
        modelContext.delete(entry)
        if let latest = latestRemaining {
            profile?.weightKg = latest.weightKg
            profile?.recalculateTargets()
        }
        modelContext.saveWithLogging()
    }

    private func yAxisRange() -> ClosedRange<Double> {
        var allValues = weightEntries.map { displayWeight($0.weightKg) }
        if let target = profile?.targetWeightKg {
            allValues.append(displayWeight(target))
        }
        let minWeight = (allValues.min() ?? 60) - 3
        let maxWeight = (allValues.max() ?? 100) + 3
        return minWeight...maxWeight
    }
}

// MARK: - Weight History Row

private struct WeightHistoryRow: View {
    let entry: WeightEntry
    let previousEntry: WeightEntry?
    let useMetric: Bool

    private static let rowDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private var diff: Double? {
        guard let prev = previousEntry else { return nil }
        return entry.weightKg - prev.weightKg
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.rowDateFormatter.string(from: entry.date))
                    .font(LebolFont.body())
                    .foregroundColor(.lebolTextPrimary)
            }

            Spacer()

            HStack(spacing: 8) {
                if let diff {
                    let displayDiff = useMetric ? diff : diff * NutritionCalculator.kgToLbs
                    if abs(displayDiff) >= 0.1 {
                        Text("\(displayDiff > 0 ? "+" : "")\(String(format: "%.1f", displayDiff))")
                            .font(LebolFont.caption())
                            .foregroundColor(diff < 0 ? .lebolSuccess : .lebolError)
                    }
                }

                Text(LebolFormatters.formatWeight(entry.weightKg, useMetric: useMetric))
                    .font(LebolFont.headline())
                    .foregroundColor(.lebolTextPrimary)
            }
        }
        .padding(.vertical, 4)
    }
}
