import SwiftUI
import SwiftData

struct ProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query private var profiles: [UserProfile]
    @State private var showingDeleteConfirmation = false
    @State private var editingField: EditableField?
    @Bindable var authViewModel: AuthViewModel

    var isSheet: Bool = true

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                // Personal info
                Section {
                    SettingsRow(title: "Gender", value: profile?.gender.rawValue ?? "") {
                        editingField = .gender
                    }

                    SettingsRow(title: "Age", value: "\(profile?.age ?? 0)") {
                        editingField = .age
                    }

                    SettingsRow(title: "Height", value: formatHeight(profile?.heightCm ?? 0)) {
                        editingField = .height
                    }
                }

                // Settings & Goals
                Section {
                    SettingsRow(title: "Measurement System", value: (profile?.useMetric ?? true) ? "Metric" : "Imperial") {
                        editingField = .measurementSystem
                    }

                    SettingsRow(title: "Weekly Goal", value: formatWeeklyGoal(profile?.weeklyGoalGrams ?? 800)) {
                        editingField = .weeklyGoal
                    }

                    SettingsRow(title: "Starting Weight", value: formatWeight(profile?.startingWeightKg ?? 0)) {
                        editingField = .startingWeight
                    }

                    SettingsRow(title: "Current Weight", value: formatWeight(profile?.weightKg ?? 0)) {
                        editingField = .currentWeight
                    }

                    SettingsRow(title: "Goal Weight", value: formatWeight(profile?.targetWeightKg ?? 0)) {
                        editingField = .goalWeight
                    }

                    NavigationLink {
                        FavoritesManagementView()
                    } label: {
                        Text("Manage Favorites")
                    }
                }

                // Help
                Section {
                    NavigationLink {
                        SupportChatView()
                    } label: {
                        Text("Customer Support")
                    }
                }

                // Account
                if profile?.isAuthenticated == true {
                    Section {
                        if let email = profile?.email {
                            HStack {
                                Text("Email")
                                    .foregroundColor(.lebolTextPrimary)
                                Spacer()
                                Text(email)
                                    .foregroundColor(.lebolTextSecondary)
                            }
                            .padding(.vertical, 4)
                        }

                        Button(role: .destructive) {
                            Task {
                                await authViewModel.signOut()
                                profile?.supabaseUserId = nil
                                profile?.email = nil
                                modelContext.saveWithLogging()
                            }
                        } label: {
                            Text("Sign Out")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete account")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listSectionSpacing(20)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.lebolTextPrimary)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.lebolDivider))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDeleteConfirmation) {
                DeleteAccountSheet {
                    deleteAllData()
                }
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.lebolBackground)
            }
            // Full-screen editors
            .sheet(item: $editingField) { field in
                switch field {
                case .height:
                    ProfileHeightEditor(initialValue: profile?.heightCm ?? 176, initialUseMetric: profile?.useMetric ?? true) { newValue in
                        profile?.heightCm = newValue
                        recalculateTargets()
                    }
                case .startingWeight:
                    ProfileWeightEditor(
                        title: "Starting weight",
                        subtitle: "This is where your journey began",
                        initialValue: profile?.startingWeightKg ?? 80,
                        initialUseMetric: profile?.useMetric ?? true
                    ) { newValue in
                        profile?.startingWeightKg = newValue
                        modelContext.saveWithLogging()
                    }
                case .currentWeight:
                    ProfileWeightEditor(
                        title: "Current weight",
                        subtitle: "Update your progress",
                        initialValue: profile?.weightKg ?? 80,
                        initialUseMetric: profile?.useMetric ?? true
                    ) { newValue in
                        profile?.weightKg = newValue
                        let entry = WeightEntry(weightKg: newValue)
                        modelContext.insert(entry)
                        recalculateTargets()
                    }
                case .goalWeight:
                    ProfileTargetWeightEditor(
                        initialValue: profile?.targetWeightKg ?? 70,
                        currentWeightKg: profile?.weightKg ?? 95,
                        heightCm: profile?.heightCm ?? 176,
                        initialUseMetric: profile?.useMetric ?? true
                    ) { newValue in
                        profile?.targetWeightKg = newValue
                        modelContext.saveWithLogging()
                    }
                case .age:
                    ProfileAgeEditor(initialValue: profile?.age ?? 26) { newValue in
                        profile?.age = newValue
                        recalculateTargets()
                    }
                case .gender:
                    ProfileGenderEditor(currentGender: profile?.gender ?? .male) { newGender in
                        profile?.gender = newGender
                        recalculateTargets()
                    }
                case .measurementSystem:
                    ProfileMeasurementSystemEditor(currentUseMetric: profile?.useMetric ?? true) { newValue in
                        profile?.useMetric = newValue
                        modelContext.saveWithLogging()
                    }
                case .weeklyGoal:
                    ProfileWeeklyGoalEditor(
                        initialValue: profile?.weeklyGoalGrams ?? 800,
                        maxValue: 1000,
                        currentWeightKg: profile?.weightKg ?? 95,
                        targetWeightKg: profile?.targetWeightKg ?? 68,
                        heightCm: profile?.heightCm ?? 176,
                        age: profile?.age ?? 26,
                        gender: profile?.gender ?? .male
                    ) { newValue in
                        profile?.weeklyGoalGrams = min(newValue, 1000)
                        recalculateTargets()
                    }
                }
            }
        }
    }

    private var useMetricValue: Bool { profile?.useMetric ?? true }

    private func formatHeight(_ cm: Double) -> String {
        LebolFormatters.formatHeight(cm, useMetric: useMetricValue)
    }

    private func formatWeeklyGoal(_ grams: Int) -> String {
        LebolFormatters.formatWeeklyGoal(grams, useMetric: useMetricValue)
    }

    private func formatWeight(_ kg: Double) -> String {
        LebolFormatters.formatWeight(kg, useMetric: useMetricValue)
    }

    private func recalculateTargets() {
        guard let profile else { return }
        profile.recalculateTargets()
        modelContext.saveWithLogging()
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: DailyLog.self)
            try modelContext.delete(model: WeightEntry.self)
            try modelContext.delete(model: WaterEntry.self)
            try modelContext.delete(model: SupportMessage.self)
            try modelContext.delete(model: FavoriteMeal.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }

        hasCompletedOnboarding = false
        if isSheet { dismiss() }
    }
}

// MARK: - Delete Account Sheet

private struct DeleteAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lebolTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.lebolDivider))
                }
            }
            .padding(.top, 16)

            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.lebolPrimary.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.lebolPrimary.opacity(0.4))

                // X badge
                ZStack {
                    Circle()
                        .fill(Color.lebolError)
                        .frame(width: 24, height: 24)
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 24, y: 24)
            }

            Spacer().frame(height: 20)

            Text("Delete account")
                .font(LebolFont.title2())
                .foregroundColor(.lebolTextPrimary)

            Spacer().frame(height: 10)

            Text("Are you sure you want to permanently delete your account? This action cannot be undone.")
                .font(LebolFont.subheadline())
                .foregroundColor(.lebolTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(LebolSecondaryButtonStyle())

                Button {
                    Haptics.error()
                    onDelete()
                    dismiss()
                } label: {
                    Text("Delete")
                        .font(LebolFont.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.lebolError)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Editable Field Enum

enum EditableField: Identifiable {
    case measurementSystem, weeklyGoal, startingWeight, currentWeight, goalWeight
    case age, height, gender

    var id: Self { self }
}

// MARK: - Settings Row (tappable)

struct SettingsRow: View {
    let title: String
    let value: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.lebolTextPrimary)
                Spacer()
                Text(value)
                    .foregroundColor(.lebolTextSecondary)
                Image(systemName: "chevron.right")
                    .font(LebolFont.caption())
                    .foregroundColor(.lebolTextSecondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

