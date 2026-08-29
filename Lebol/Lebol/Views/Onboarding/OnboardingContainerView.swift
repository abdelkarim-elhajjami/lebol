import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var authViewModel = AuthViewModel()
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            // Navigation + progress bar — always takes space for stable layout
            HStack(spacing: 8) {
                // Back button: visible on all steps except welcome, programLoader, accountCreation, roadmap
                let showsBack = viewModel.currentStep != .welcome
                    && viewModel.currentStep != .programLoader
                    && viewModel.currentStep != .accountCreation
                    && viewModel.currentStep != .roadmap

                Button {
                    viewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lebolTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
                .opacity(showsBack ? 1 : 0)
                .allowsHitTesting(showsBack)

                OnboardingProgressBar(
                    sections: ["Welcome", "Info", "Plan"],
                    currentSectionIndex: viewModel.currentStep.sectionIndex,
                    progressInSection: viewModel.progressInSection
                )
                .opacity(viewModel.currentStep.showsProgressBar ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Content
            TabView(selection: $viewModel.currentStep) {
                WelcomeStepView(viewModel: viewModel, authViewModel: authViewModel)
                    .tag(OnboardingStep.welcome)
                PrivacyStepView(viewModel: viewModel)
                    .tag(OnboardingStep.privacy)
                GenderStepView(viewModel: viewModel)
                    .tag(OnboardingStep.gender)
                MeasurementSystemStepView(viewModel: viewModel)
                    .tag(OnboardingStep.measurementSystem)
                AgeStepView(viewModel: viewModel)
                    .tag(OnboardingStep.age)
                HeightStepView(viewModel: viewModel)
                    .tag(OnboardingStep.height)
                WeightStepView(viewModel: viewModel)
                    .tag(OnboardingStep.weight)
                MedicalDisclaimerStepView(viewModel: viewModel)
                    .tag(OnboardingStep.medicalDisclaimer)
                TargetWeightStepView(viewModel: viewModel)
                    .tag(OnboardingStep.targetWeight)
                PaceStepView(viewModel: viewModel)
                    .tag(OnboardingStep.pace)
                ProgramLoaderStepView(viewModel: viewModel)
                    .tag(OnboardingStep.programLoader)
                AccountCreationStepView(
                    viewModel: viewModel,
                    authViewModel: authViewModel,
                    onSkip: { viewModel.nextStep() }
                )
                    .tag(OnboardingStep.accountCreation)
                RoadmapStepView(viewModel: viewModel, onComplete: completeOnboarding)
                    .tag(OnboardingStep.roadmap)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .scrollDisabled(true)
            .highPriorityGesture(
                DragGesture(),
                including: viewModel.currentStep.hasDragDependentUI ? .subviews : .all
            )
        }
        .background(Color.lebolBackground)
        .onChange(of: authViewModel.signedInFromWelcome) { _, signedIn in
            if signedIn {
                viewModel.skipAccountCreation = true
            }
        }
    }

    private func completeOnboarding() {
        let profile = viewModel.createProfile(modelContext: modelContext)

        // If authenticated, link auth to profile and push all local data to cloud
        if authViewModel.isAuthenticated,
           let userId = authViewModel.currentUserId {
            profile.supabaseUserId = userId
            profile.email = authViewModel.userEmail
            modelContext.saveWithLogging()
            Task {
                await SyncService.shared.pushAllLocalData(userId: userId, modelContext: modelContext)
            }
        }

        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
