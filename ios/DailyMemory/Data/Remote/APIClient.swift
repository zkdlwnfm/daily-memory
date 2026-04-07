import Foundation
import FirebaseAuth

/// Centralized API client for DailyMemory backend
actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession

    private init() {
        self.baseURL = Constants.API.baseURL
        self.session = URLSession.shared
    }

    // MARK: - Firebase Token

    private func getAuthToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.notAuthenticated
        }
        return try await user.getIDToken()
    }

    // MARK: - Requests

    func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = URL(string: "\(baseURL)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Attach Firebase auth token
        let token = try await getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        print("[APIClient] POST \(path)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("[APIClient] Response: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "nil"
                print("[APIClient] Decode error: \(error)\nRaw: \(raw)")
                throw error
            }
        case 401:
            throw APIError.notAuthenticated
        case 429:
            throw APIError.rateLimited
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[APIClient] Error \(httpResponse.statusCode): \(message)")
            throw APIError.serverError(httpResponse.statusCode, message)
        }
    }

    func delete(_ path: String) async throws {
        let url = URL(string: "\(baseURL)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let token = try await getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - Connectivity Check

    var isAvailable: Bool {
        get async {
            guard let url = URL(string: "\(baseURL)/health") else { return false }
            do {
                let (_, response) = try await session.data(from: url)
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        }
    }
}

// MARK: - Response Models

struct PersonExtracted: Decodable {
    let name: String
    let relationship: String
}

struct AnalysisResponse: Decodable {
    let persons: [PersonExtracted]
    let location: String?
    let date: String?
    let amount: Double?
    let tags: [String]
    let category: String
    let mood: String?
    let moodScore: Int?
    let summary: String
}

struct ImageAnalysisResponse: Decodable {
    let objects: [String]
    let scene: String
    let text: String?
    let faces: Int
    let description: String
    let suggestedTags: [String]
}

struct EmbeddingResponse: Decodable {
    let embedding: [Float]
    let dimensions: Int
}

struct StoreEmbeddingResponse: Decodable {
    let memoryId: String
    let dimensions: Int
    let stored: Bool
}

struct SemanticSearchResponse: Decodable {
    let results: [SemanticSearchHit]
    let count: Int
}

struct SemanticSearchHit: Decodable {
    let memoryId: String
    let similarity: Float
}

// MARK: - Errors

enum APIError: LocalizedError {
    case notAuthenticated
    case rateLimited
    case serverError(Int, String)
    case invalidResponse
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to use AI features"
        case .rateLimited: return "Daily usage limit reached. Upgrade to Premium for more."
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .invalidResponse: return "Invalid response from server"
        case .serverUnavailable: return "Server is unavailable. Using offline mode."
        }
    }
}
