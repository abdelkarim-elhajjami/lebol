import Foundation
import SwiftUI
import Supabase
import AuthenticationServices

// MARK: - Protocol for dependency injection and testability

protocol AuthServiceProtocol: Sendable {
    func signInWithEmail(_ email: String, password: String) async throws -> String
    func signUpWithEmail(_ email: String, password: String) async throws -> String
    func signInWithApple(idToken: String, nonce: String) async throws -> String
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> String
    func signOut() async throws
    func restoreSession() async -> String?
    func currentUserId() async -> String?
}

// MARK: - SwiftUI Environment Key

struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthServiceProtocol = AuthService.shared
}

extension EnvironmentValues {
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingCredentials
    case notConfigured
    case signInFailed(String)
    case signUpFailed(String)
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .missingCredentials: return "Email and password are required."
        case .notConfigured: return "Authentication is not configured."
        case .signInFailed(let msg): return "Sign in failed: \(msg)"
        case .signUpFailed(let msg): return "Sign up failed: \(msg)"
        case .sessionExpired: return "Your session has expired. Please sign in again."
        }
    }
}

// MARK: - Implementation

/// Thread-safe auth service. All stored properties are `let`, making it truly Sendable.
final class AuthService: AuthServiceProtocol, Sendable {
    static let shared = AuthService()

    /// The Supabase client, or nil if credentials are missing/invalid.
    let client: SupabaseClient?

    /// Whether auth is available (client was successfully created).
    var isConfigured: Bool { client != nil }

    private init() {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            self.client = nil
            return
        }
        let url = APIConfig.supabaseURL
        let key = APIConfig.supabaseAnonKey
        guard let supabaseURL = URL(string: url),
              !key.isEmpty,
              key.hasPrefix("eyJ") else {
            self.client = nil
            return
        }
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
    }

    func signInWithEmail(_ email: String, password: String) async throws -> String {
        guard let client else { throw AuthError.notConfigured }
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.missingCredentials
        }

        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return session.user.id.uuidString
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    func signUpWithEmail(_ email: String, password: String) async throws -> String {
        guard let client else { throw AuthError.notConfigured }
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.missingCredentials
        }

        do {
            let response = try await client.auth.signUp(email: email, password: password)
            guard let session = response.session else {
                throw AuthError.signUpFailed("Account created but confirmation may be required.")
            }
            return session.user.id.uuidString
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> String {
        guard let client else { throw AuthError.notConfigured }
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            return session.user.id.uuidString
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> String {
        guard let client else { throw AuthError.notConfigured }
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
            )
            return session.user.id.uuidString
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    func signOut() async throws {
        guard let client else { throw AuthError.notConfigured }
        try await client.auth.signOut()
    }

    func restoreSession() async -> String? {
        guard let client else { return nil }
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString
        } catch {
            return nil
        }
    }

    func currentUserId() async -> String? {
        guard let client else { return nil }
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString
        } catch {
            return nil
        }
    }
}
