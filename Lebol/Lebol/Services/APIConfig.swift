import Foundation

enum APIConfig {
    static var openRouterAPIKey: String {
        // Read from Info.plist (injected via Secrets.xcconfig)
        Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String ?? ""
    }

    static var supabaseURL: String {
        let host = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_HOST") as? String ?? ""
        return host.isEmpty ? "" : "https://\(host)"
    }

    static var supabaseAnonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }
}
