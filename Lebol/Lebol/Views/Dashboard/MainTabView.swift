import SwiftUI

struct MainTabView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showingAddSheet = false
    @State private var selectedDate = Date()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NutritionDashboardView(showingAddSheet: $showingAddSheet, selectedDate: $selectedDate, authViewModel: authViewModel)
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                WeightProgressView(authViewModel: authViewModel)
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)
            }

            // Bottom bar: 2 tabs evenly spaced + room for FAB
            HStack(spacing: 0) {
                TabBarItem(icon: "fork.knife", title: "Nutrition", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }

                TabBarItem(icon: "chart.bar.fill", title: "Progress", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                // Reserve space for FAB so tabs center in the remaining area
                Spacer()
                    .frame(width: 56)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            // FAB (floating at bottom-right)
            HStack {
                Spacer()
                Button {
                    Haptics.medium()
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.lebolPrimary))
                        .shadow(color: .lebolPrimary.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddActionSheet(logDate: selectedDate)
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.lebolBackground)
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .lebolPrimary : .lebolTextPrimary)
            .frame(maxWidth: .infinity)
        }
    }
}
