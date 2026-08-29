import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if hasCompletedOnboarding && !profiles.isEmpty {
                MainTabView(authViewModel: authViewModel)
            } else {
                OnboardingContainerView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}
