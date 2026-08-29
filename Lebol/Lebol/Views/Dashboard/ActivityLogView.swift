import SwiftUI
import SwiftData

struct ActivityLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.foodAnalysisService) private var foodAnalysisService
    @Query private var profiles: [UserProfile]
    @State private var selectedActivity: ActivityType = .walking
    @State private var durationMinutes = ""
    @State private var caloriesBurned = ""
    @State private var customActivity = ""
    @State private var isEstimating = false

    private var userWeight: Double { profiles.first?.weightKg ?? 70 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Activity type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Type")
                            .font(LebolFont.headline())

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(ActivityType.allCases, id: \.self) { type in
                                Button {
                                    selectedActivity = type
                                    if type != .other {
                                        caloriesBurned = "\(estimateCalories(for: type))"
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.symbolName)
                                            .font(.title3)
                                            .foregroundColor(selectedActivity == type ? .white : .lebolPrimary)
                                        Text(type.rawValue)
                                            .font(LebolFont.caption())
                                            .foregroundColor(selectedActivity == type ? .white : .lebolTextPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedActivity == type ? Color.lebolPrimary : Color.lebolDivider)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Custom activity description (shown when "Other" is selected)
                    if selectedActivity == .other {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe your activity")
                                .font(LebolFont.headline())
                            TextField("e.g. dancing, gardening, hiking", text: $customActivity)
                                .lebolTextFieldStyle()
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(LebolFont.headline())
                        HStack {
                            TextField("30", text: $durationMinutes)
                                .lebolTextFieldStyle()
                                .keyboardType(.numberPad)
                            Text("minutes")
                                .font(LebolFont.subheadline())
                                .foregroundColor(.lebolTextSecondary)
                        }
                    }

                    // Calories burned
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calories Burned")
                            .font(LebolFont.headline())
                        HStack {
                            TextField("0", text: $caloriesBurned)
                                .lebolTextFieldStyle()
                                .keyboardType(.numberPad)
                            Text("kcal")
                                .font(LebolFont.subheadline())
                                .foregroundColor(.lebolTextSecondary)
                        }
                        if selectedActivity == .other && !customActivity.isEmpty {
                            Text("AI will estimate calories from your description")
                                .font(LebolFont.caption())
                                .foregroundColor(.lebolTextTertiary)
                        } else {
                            Text("MET-based estimate for \(Int(userWeight)) kg, \(durationMinutes.isEmpty ? "30" : durationMinutes) min")
                                .font(LebolFont.caption())
                                .foregroundColor(.lebolTextTertiary)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEstimating {
                        ProgressView()
                            .tint(.lebolPrimary)
                    } else {
                        Button("Save") {
                            Task { await saveActivity() }
                        }
                        .disabled(caloriesBurned.isEmpty)
                        .foregroundColor(.lebolPrimary)
                    }
                }
            }
            .onAppear {
                caloriesBurned = "\(estimateCalories(for: selectedActivity))"
            }
            .onChange(of: durationMinutes) { _, _ in
                if selectedActivity != .other {
                    caloriesBurned = "\(estimateCalories(for: selectedActivity))"
                }
            }
        }
    }

    private func estimateCalories(for activity: ActivityType) -> Int {
        let minutes = Int(durationMinutes) ?? 30
        return NutritionCalculator.calculateActivityCalories(
            met: activity.metValue,
            weightKg: userWeight,
            durationMinutes: minutes
        )
    }

    private func saveActivity() async {
        // For "Other" with a description, use AI to estimate
        if selectedActivity == .other && !customActivity.trimmingCharacters(in: .whitespaces).isEmpty {
            isEstimating = true
            do {
                let result = try await foodAnalysisService.interpretActivity(customActivity, weightKg: userWeight)
                caloriesBurned = "\(result.caloriesBurned)"
                isEstimating = false
            } catch {
                isEstimating = false
                // Fall back to manual calories if AI fails
            }
        }

        guard let burned = Double(caloriesBurned), burned > 0 else { return }

        DataService.logActivity(burned: burned, in: modelContext)

        dismiss()
    }
}

enum ActivityType: String, CaseIterable {
    case walking = "Walking"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case gym = "Gym"
    case yoga = "Yoga"
    case hiit = "HIIT"
    case other = "Other"

    var symbolName: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .gym: return "figure.strengthtraining.traditional"
        case .yoga: return "figure.yoga"
        case .hiit: return "figure.highintensity.intervaltraining"
        case .other: return "figure.mixed.cardio"
        }
    }

    /// MET values from the Compendium of Physical Activities
    var metValue: Double {
        switch self {
        case .walking:  return 4.3   // Walking 3.5 mph
        case .running:  return 9.8   // Running 6 mph
        case .cycling:  return 8.0   // Cycling, moderate
        case .swimming: return 5.8   // Swimming, moderate
        case .gym:      return 6.0   // Weight training
        case .yoga:     return 3.0   // Yoga
        case .hiit:     return 8.0   // High-intensity interval training
        case .other:    return 5.0   // General moderate activity
        }
    }
}
