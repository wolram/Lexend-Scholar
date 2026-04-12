// LS-42: Integrar Supabase Swift SDK para autenticação
import Foundation
import SwiftUI

// MARK: - Supabase Configuration

enum SupabaseConfig {
    static let url: URL = {
        let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? "https://your-project.supabase.co"
        return URL(string: urlString)!
    }()

    static let anonKey: String = {
        return Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? "your-anon-key"
    }()
}

// MARK: - Auth Models

struct SupabaseUser: Identifiable, Codable {
    let id: String
    let email: String?
    let role: UserRole

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
    }
}

enum UserRole: String, Codable, CaseIterable {
    case diretor
    case professor
    case secretario

    var displayName: String {
        switch self {
        case .diretor: return "Diretor"
        case .professor: return "Professor"
        case .secretario: return "Secretário"
        }
    }

    var symbol: String {
        switch self {
        case .diretor: return "building.columns.fill"
        case .professor: return "person.text.rectangle.fill"
        case .secretario: return "doc.text.fill"
        }
    }

    var accent: Color {
        switch self {
        case .diretor: return SchoolPalette.primary
        case .professor: return SchoolPalette.violet
        case .secretario: return SchoolPalette.success
        }
    }
}

// MARK: - Auth Token

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: SupabaseUser

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

// MARK: - Supabase Error

enum SupabaseError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case sessionExpired
    case unauthorized
    case notFound
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "E-mail ou senha incorretos."
        case .networkError(let msg): return "Erro de rede: \(msg)"
        case .sessionExpired: return "Sessão expirada. Faça login novamente."
        case .unauthorized: return "Acesso não autorizado."
        case .notFound: return "Recurso não encontrado."
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - HTTP Helpers

private struct SupabaseHTTPClient {
    let baseURL: URL
    let anonKey: String
    var accessToken: String?

    func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.networkError("Resposta inválida")
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 { throw SupabaseError.unauthorized }
            if http.statusCode == 404 { throw SupabaseError.notFound }
            let body = String(data: data, encoding: .utf8) ?? "desconhecido"
            throw SupabaseError.unknown("HTTP \(http.statusCode): \(body)")
        }
        return data
    }
}

// MARK: - SupabaseService

@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    @Published private(set) var currentUser: SupabaseUser?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false

    private var session: AuthSession?
    private let sessionKey = "lexend_auth_session"

    private var http: SupabaseHTTPClient

    private init() {
        http = SupabaseHTTPClient(baseURL: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey)
        restoreSession()
    }

    // MARK: - Session Persistence

    private func restoreSession() {
        guard
            let data = UserDefaults.standard.data(forKey: sessionKey),
            let saved = try? JSONDecoder().decode(AuthSession.self, from: data),
            !saved.isExpired
        else { return }

        session = saved
        http.accessToken = saved.accessToken
        currentUser = saved.user
        isAuthenticated = true
    }

    private func persistSession(_ session: AuthSession) {
        self.session = session
        http.accessToken = session.accessToken
        currentUser = session.user
        isAuthenticated = true
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    // MARK: - Auth Operations

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let payload = ["email": email, "password": password]
        let body = try JSONEncoder().encode(payload)

        let data = try await http.request(
            path: "/auth/v1/token?grant_type=password",
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        let user = SupabaseUser(
            id: response.user.id,
            email: response.user.email,
            role: response.user.appMetadata?.role ?? .secretario
        )
        let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        let authSession = AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt,
            user: user
        )
        persistSession(authSession)
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        _ = try? await http.request(path: "/auth/v1/logout", method: "POST")

        session = nil
        http.accessToken = nil
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func refreshSessionIfNeeded() async throws {
        guard let current = session, current.isExpired else { return }

        let payload = ["refresh_token": current.refreshToken]
        let body = try JSONEncoder().encode(payload)
        let data = try await http.request(
            path: "/auth/v1/token?grant_type=refresh_token",
            method: "POST",
            body: body
        )
        let response = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        let user = SupabaseUser(
            id: response.user.id,
            email: response.user.email,
            role: response.user.appMetadata?.role ?? .secretario
        )
        let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        let authSession = AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt,
            user: user
        )
        persistSession(authSession)
    }

    // MARK: - Database Operations

    func fetch<T: Decodable>(from table: String, queryItems: [URLQueryItem] = []) async throws -> [T] {
        try await refreshSessionIfNeeded()
        let data = try await http.request(
            path: "/rest/v1/\(table)",
            queryItems: queryItems
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([T].self, from: data)
    }

    func insert<T: Encodable>(into table: String, value: T) async throws -> Data {
        try await refreshSessionIfNeeded()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(value)
        return try await http.request(path: "/rest/v1/\(table)", method: "POST", body: body)
    }

    func update<T: Encodable>(table: String, id: String, value: T) async throws -> Data {
        try await refreshSessionIfNeeded()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(value)
        return try await http.request(
            path: "/rest/v1/\(table)",
            method: "PATCH",
            body: body,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id)")]
        )
    }

    func delete(from table: String, id: String) async throws {
        try await refreshSessionIfNeeded()
        _ = try await http.request(
            path: "/rest/v1/\(table)",
            method: "DELETE",
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id)")]
        )
    }
}

// MARK: - Auth Token Response

private struct AuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUserResponse

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

private struct AuthUserResponse: Decodable {
    let id: String
    let email: String?
    let appMetadata: AppMetadata?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case appMetadata = "app_metadata"
    }
}

private struct AppMetadata: Decodable {
    let role: UserRole?
}
