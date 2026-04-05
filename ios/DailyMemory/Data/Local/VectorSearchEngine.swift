import Foundation
import Accelerate

/// Engine for vector similarity search using cosine similarity
/// Stores and searches embeddings for memories
final class VectorSearchEngine {
    static let shared = VectorSearchEngine()

    // MARK: - Storage
    private var memoryEmbeddings: [String: [Float]] = [:] // memoryId -> embedding
    private let storageKey = "memory_embeddings"
    private let fileManager = FileManager.default

    // MARK: - Configuration
    private let similarityThreshold: Float = 0.5
    private let maxResults = 20

    // MARK: - Initialization
    private init() {
        loadEmbeddings()
    }

    // MARK: - Embedding Management

    /// Store embedding for a memory
    func storeEmbedding(_ embedding: [Float], for memoryId: String) {
        memoryEmbeddings[memoryId] = embedding
        saveEmbeddings()
    }

    /// Store multiple embeddings
    func storeEmbeddings(_ embeddings: [(memoryId: String, embedding: [Float])]) {
        for (memoryId, embedding) in embeddings {
            memoryEmbeddings[memoryId] = embedding
        }
        saveEmbeddings()
    }

    /// Remove embedding for a memory
    func removeEmbedding(for memoryId: String) {
        memoryEmbeddings.removeValue(forKey: memoryId)
        saveEmbeddings()
    }

    /// Check if memory has embedding
    func hasEmbedding(for memoryId: String) -> Bool {
        return memoryEmbeddings[memoryId] != nil
    }

    /// Get embedding for a memory
    func getEmbedding(for memoryId: String) -> [Float]? {
        return memoryEmbeddings[memoryId]
    }

    /// Get all memory IDs with embeddings
    func getAllMemoryIds() -> [String] {
        return Array(memoryEmbeddings.keys)
    }

    // MARK: - Search

    /// Search for similar memories using query embedding
    /// Returns memory IDs sorted by similarity (highest first)
    func search(
        queryEmbedding: [Float],
        limit: Int? = nil,
        threshold: Float? = nil
    ) -> [SearchResult] {
        let effectiveThreshold = threshold ?? similarityThreshold
        let effectiveLimit = limit ?? maxResults

        var results: [SearchResult] = []

        for (memoryId, embedding) in memoryEmbeddings {
            let similarity = cosineSimilarity(queryEmbedding, embedding)

            if similarity >= effectiveThreshold {
                results.append(SearchResult(memoryId: memoryId, similarity: similarity))
            }
        }

        // Sort by similarity descending
        results.sort { $0.similarity > $1.similarity }

        // Limit results
        if results.count > effectiveLimit {
            results = Array(results.prefix(effectiveLimit))
        }

        return results
    }

    /// Search excluding specific memory IDs
    func search(
        queryEmbedding: [Float],
        excluding excludedIds: Set<String>,
        limit: Int? = nil,
        threshold: Float? = nil
    ) -> [SearchResult] {
        let effectiveThreshold = threshold ?? similarityThreshold
        let effectiveLimit = limit ?? maxResults

        var results: [SearchResult] = []

        for (memoryId, embedding) in memoryEmbeddings {
            if excludedIds.contains(memoryId) { continue }

            let similarity = cosineSimilarity(queryEmbedding, embedding)

            if similarity >= effectiveThreshold {
                results.append(SearchResult(memoryId: memoryId, similarity: similarity))
            }
        }

        results.sort { $0.similarity > $1.similarity }

        if results.count > effectiveLimit {
            results = Array(results.prefix(effectiveLimit))
        }

        return results
    }

    // MARK: - Similarity Calculation

    /// Calculate cosine similarity between two vectors
    /// Uses Accelerate framework for optimized computation
    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0

        // Use Accelerate for SIMD optimization
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_dotpr(a, 1, a, 1, &magnitudeA, vDSP_Length(a.count))
        vDSP_dotpr(b, 1, b, 1, &magnitudeB, vDSP_Length(b.count))

        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)

        guard magnitude > 0 else { return 0 }

        return dotProduct / magnitude
    }

    /// Calculate Euclidean distance between two vectors
    func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return Float.infinity }

        var diff = [Float](repeating: 0, count: a.count)
        vDSP_vsub(b, 1, a, 1, &diff, 1, vDSP_Length(a.count))

        var sumSquared: Float = 0
        vDSP_dotpr(diff, 1, diff, 1, &sumSquared, vDSP_Length(diff.count))

        return sqrt(sumSquared)
    }

    // MARK: - Persistence

    private var embeddingsFileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("vector_embeddings.json")
    }

    private func saveEmbeddings() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            do {
                // Convert to serializable format
                let serializable = self.memoryEmbeddings.mapValues { embedding in
                    embedding.map { Double($0) }
                }

                let data = try JSONSerialization.data(withJSONObject: serializable)
                try data.write(to: self.embeddingsFileURL)
            } catch {
                print("Failed to save embeddings: \(error)")
            }
        }
    }

    private func loadEmbeddings() {
        guard fileManager.fileExists(atPath: embeddingsFileURL.path) else { return }

        do {
            let data = try Data(contentsOf: embeddingsFileURL)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: [Double]] else {
                return
            }

            memoryEmbeddings = dict.mapValues { doubles in
                doubles.map { Float($0) }
            }
        } catch {
            print("Failed to load embeddings: \(error)")
        }
    }

    // MARK: - Maintenance

    /// Clear all embeddings
    func clearAll() {
        memoryEmbeddings.removeAll()
        try? fileManager.removeItem(at: embeddingsFileURL)
    }

    /// Get storage statistics
    func getStats() -> EmbeddingStats {
        let count = memoryEmbeddings.count
        let dimensions = memoryEmbeddings.values.first?.count ?? 0
        let estimatedSizeBytes = count * dimensions * MemoryLayout<Float>.size

        return EmbeddingStats(
            count: count,
            dimensions: dimensions,
            estimatedSizeBytes: estimatedSizeBytes
        )
    }

    /// Remove embeddings for memories that no longer exist
    func cleanup(existingMemoryIds: Set<String>) {
        let idsToRemove = Set(memoryEmbeddings.keys).subtracting(existingMemoryIds)

        for id in idsToRemove {
            memoryEmbeddings.removeValue(forKey: id)
        }

        if !idsToRemove.isEmpty {
            saveEmbeddings()
        }
    }
}

// MARK: - Models

struct SearchResult: Identifiable, Equatable {
    let memoryId: String
    let similarity: Float

    var id: String { memoryId }

    /// Similarity as percentage (0-100)
    var similarityPercent: Int {
        Int(similarity * 100)
    }
}

struct EmbeddingStats {
    let count: Int
    let dimensions: Int
    let estimatedSizeBytes: Int

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(estimatedSizeBytes))
    }
}
