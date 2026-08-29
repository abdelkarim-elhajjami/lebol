import SwiftUI
import SwiftData

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @Bindable var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                // Email field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .lebolTextFieldStyle()
                }

                Spacer().frame(height: 16)

                // Password field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .lebolTextFieldStyle()
                }

                if let error = authViewModel.error {
                    Text(error)
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolError)
                        .padding(.top, 12)
                }

                Spacer()

                // Continue button
                Button {
                    Task {
                        let userId: String?
                        if isSignUp {
                            userId = await authViewModel.signUpWithEmail(email: email, password: password)
                        } else {
                            userId = await authViewModel.signInWithEmail(email: email, password: password)
                        }

                        if let userId {
                            // Try to pull existing data from cloud
                            let hasCloudData = try? await SyncService.shared.pullAll(
                                userId: userId,
                                modelContext: modelContext
                            )
                            if hasCloudData == true {
                                withAnimation { hasCompletedOnboarding = true }
                            }
                            authViewModel.signedInFromWelcome = true
                            dismiss()
                        }
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(LebolPrimaryButtonStyle())
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                // Toggle sign in / sign up
                Button {
                    isSignUp.toggle()
                    authViewModel.error = nil
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(LebolFont.footnote())
                        .foregroundColor(.lebolTextSecondary)
                }
                .padding(.top, 12)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
            .background(Color.lebolBackground)
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.lebolTextPrimary)
                    }
                }
            }
        }
    }
}
