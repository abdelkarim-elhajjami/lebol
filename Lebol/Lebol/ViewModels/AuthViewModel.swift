import SwiftUI
import SwiftData
import AuthenticationServices
import CryptoKit

@MainActor @Observable
final class AuthViewModel {
    var isAuthenticated = false
    var currentUserId: String?
    var userEmail: String?
    var isLoading = false
    var error: String?
    var signedInFromWelcome = false

    private let authService: AuthServiceProtocol

    // Apple Sign In state
    private var currentNonce: String?

    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }

    // MARK: - Session Restore

    func restoreSession() async {
        if let userId = await authService.restoreSession() {
            isAuthenticated = true
            currentUserId = userId
        }
    }

    // MARK: - Email Auth

    func signInWithEmail(email: String, password: String) async -> String? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let userId = try await authService.signInWithEmail(email, password: password)
            isAuthenticated = true
            currentUserId = userId
            userEmail = email
            return userId
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func signUpWithEmail(email: String, password: String) async -> String? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let userId = try await authService.signUpWithEmail(email, password: password)
            isAuthenticated = true
            currentUserId = userId
            userEmail = email
            return userId
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Apple Sign In

    func prepareAppleSignIn() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        return request
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> String? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                self.error = "Failed to get Apple credentials."
                return nil
            }

            do {
                let userId = try await authService.signInWithApple(idToken: idToken, nonce: nonce)
                isAuthenticated = true
                currentUserId = userId
                userEmail = credential.email
                return userId
            } catch {
                self.error = error.localizedDescription
                return nil
            }

        case .failure(let error):
            // User cancelled — don't show error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                self.error = error.localizedDescription
            }
            return nil
        }
    }

    // MARK: - Google Sign In (placeholder — requires GoogleSignIn SDK)

    func signInWithGoogle() async -> String? {
        error = "Google Sign-In is not yet configured. Please use Apple or email."
        return nil
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authService.signOut()
            isAuthenticated = false
            currentUserId = nil
            userEmail = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Link auth to profile

    func linkAuthToProfile(_ profile: UserProfile, userId: String, email: String?) {
        profile.supabaseUserId = userId
        profile.email = email
    }

    // MARK: - Apple Sign In Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce: \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
