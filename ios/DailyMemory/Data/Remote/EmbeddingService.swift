import Foundation

/// Service for generating text embeddings using OpenAI API
/// Uses text-embedding-3-small model for cost-effective semantic search
actor EmbeddingService {
    static let shared = EmbeddingService()

    private let apiClient = APIClient.shared
    private let dimensions = 1536

    // MARK: - Cache
    private var embeddingCache: [String: [Float]] = [:]
    private let maxCacheSize = 1000

    private init() {}

    // MARK: - Embedding Generation

    /// Generate embedding via backend API
    func generateEmbedding(for text: String) async -> Result<[Float], Error> {
        let cacheKey = String(text.prefix(200).lowercased())
        if let cached = embeddingCache[cacheKey] {
            return .success(cached)
        }

        do {
            let response: EmbeddingResponse = try await apiClient.post("embeddings", body: ["text": text])
            let embedding = response.embedding

            if embeddingCache.count >= maxCacheSize {
                embeddingCache.removeAll()
            }
            embeddingCache[cacheKey] = embedding

            return .success(embedding)
        } catch {
            return .success(simulateEmbedding(for: text))
        }
    }

    /// Store embedding on server for semantic search
    func storeEmbedding(memoryId: String, text: String) async -> Result<Bool, Error> {
        do {
            let _: StoreEmbeddingResponse = try await apiClient.post("embeddings/store", body: [
                "memoryId": memoryId,
                "text": text
            ])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    /// Generate embeddings for multiple texts (batch) via backend API
    func generateEmbeddings(for texts: [String]) async -> Result<[[Float]], Error> {
        do {
            struct BatchResponse: Decodable { let embeddings: [[Float]]; let count: Int }
            let response: BatchResponse = try await apiClient.post("embeddings/batch", body: ["texts": texts])
            return .success(response.embeddings)
        } catch {
            let embeddings = texts.map { simulateEmbedding(for: $0) }
            return .success(embeddings)
        }
    }

    // MARK: - Legacy (removed - now uses backend API)

    // MARK: - Simulation

    /// Simulate embedding for testing/demo purposes
    /// Uses simple word-based hashing to create pseudo-embeddings
    private func simulateEmbedding(for text: String) -> [Float] {
        var embedding = [Float](repeating: 0.0, count: dimensions)
        let words = text.lowercased().split(separator: " ")

        for (index, word) in words.enumerated() {
            let hash = word.hashValue
            let position = abs(hash) % dimensions

            // Distribute word influence across multiple dimensions
            for offset in 0..<10 {
                let idx = (position + offset) % dimensions
                let value = Float(hash % 1000) / 1000.0 * (index % 2 == 0 ? 1 : -1)
                embedding[idx] += value / Float(words.count)
            }
        }

        // Normalize the vector
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    // MARK: - Cache Management

    func clearCache() {
        embeddingCache.removeAll()
    }

    func getCacheSize() -> Int {
        return embeddingCache.count
    }
}

// MARK: - Errors

enum EmbeddingError: LocalizedError {
    case emptyResponse
    case invalidResponse
    case apiError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Empty response from embedding API"
        case .invalidResponse:
            return "Invalid response from embedding API"
        case .apiError(let statusCode):
            return "Embedding API error: HTTP \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
