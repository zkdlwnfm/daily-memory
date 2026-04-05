import Foundation

/// Use case for semantic (AI-powered) search of memories
/// Combines vector similarity search with traditional keyword search
final class SemanticSearchUseCase {
    private let embeddingService: EmbeddingService
    private let vectorSearchEngine: VectorSearchEngine
    private let memoryRepository: MemoryRepository

    init(
        embeddingService: EmbeddingService = .shared,
        vectorSearchEngine: VectorSearchEngine = .shared,
        memoryRepository: MemoryRepository = DIContainer.shared.memoryRepository
    ) {
        self.embeddingService = embeddingService
        self.vectorSearchEngine = vectorSearchEngine
        self.memoryRepository = memoryRepository
    }

    // MARK: - Search

    /// Perform semantic search with natural language query
    func execute(query: String, limit: Int = 20) async -> Result<[SemanticSearchResult], Error> {
        // Generate embedding for query
        let embeddingResult = await embeddingService.generateEmbedding(for: query)

        switch embeddingResult {
        case .success(let queryEmbedding):
            // Search for similar memories
            let searchResults = vectorSearchEngine.search(
                queryEmbedding: queryEmbedding,
                limit: limit,
                threshold: 0.4 // Lower threshold for more results
            )

            // Fetch actual memories
            var semanticResults: [SemanticSearchResult] = []

            for result in searchResults {
                do {
                    if let memory = try await memoryRepository.getById( result.memoryId) {
                        semanticResults.append(SemanticSearchResult(
                            memory: memory,
                            similarity: result.similarity,
                            matchType: .semantic
                        ))
                    }
                } catch {
                    // Skip memories that can't be fetched
                    continue
                }
            }

            return .success(semanticResults)

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Perform hybrid search (semantic + keyword)
    func executeHybrid(
        query: String,
        limit: Int = 20
    ) async -> Result<[SemanticSearchResult], Error> {
        async let semanticTask = execute(query: query, limit: limit)
        async let keywordTask = performKeywordSearch(query: query)

        let semanticResult = await semanticTask
        let keywordResult = await keywordTask

        // Merge results
        var resultMap: [String: SemanticSearchResult] = [:]

        // Add semantic results
        if case .success(let semanticResults) = semanticResult {
            for result in semanticResults {
                resultMap[result.memory.id] = result
            }
        }

        // Add/merge keyword results
        if case .success(let keywordResults) = keywordResult {
            for result in keywordResults {
                if let existing = resultMap[result.memory.id] {
                    // Boost score for memories found by both methods
                    resultMap[result.memory.id] = SemanticSearchResult(
                        memory: result.memory,
                        similarity: min(existing.similarity + 0.2, 1.0),
                        matchType: .hybrid
                    )
                } else {
                    resultMap[result.memory.id] = result
                }
            }
        }

        // Sort by similarity and limit
        let sortedResults = resultMap.values
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)

        return .success(Array(sortedResults))
    }

    // MARK: - Embedding Management

    /// Generate and store embedding for a memory
    func indexMemory(_ memory: Memory) async {
        let embeddingResult = await embeddingService.generateEmbedding(for: memory.content)

        if case .success(let embedding) = embeddingResult {
            vectorSearchEngine.storeEmbedding(embedding, for: memory.id)
        }
    }

    /// Generate and store embeddings for multiple memories
    func indexMemories(_ memories: [Memory]) async {
        let texts = memories.map { $0.content }
        let embeddingsResult = await embeddingService.generateEmbeddings(for: texts)

        if case .success(let embeddings) = embeddingsResult {
            let pairs = zip(memories, embeddings).map { (memoryId: $0.id, embedding: $1) }
            vectorSearchEngine.storeEmbeddings(Array(pairs))
        }
    }

    /// Remove embedding when memory is deleted
    func removeIndex(for memoryId: String) {
        vectorSearchEngine.removeEmbedding(for: memoryId)
    }

    /// Check if memory is indexed
    func isIndexed(memoryId: String) -> Bool {
        return vectorSearchEngine.hasEmbedding(for: memoryId)
    }

    /// Index all unindexed memories
    func indexAllUnindexed() async -> Int {
        do {
            let allMemories = try await memoryRepository.getAll()
            let unindexedMemories = allMemories.filter { !vectorSearchEngine.hasEmbedding(for: $0.id) }

            if unindexedMemories.isEmpty { return 0 }

            // Index in batches of 20
            let batchSize = 20
            var indexedCount = 0

            for batchStart in stride(from: 0, to: unindexedMemories.count, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, unindexedMemories.count)
                let batch = Array(unindexedMemories[batchStart..<batchEnd])

                await indexMemories(batch)
                indexedCount += batch.count
            }

            return indexedCount
        } catch {
            return 0
        }
    }

    /// Cleanup orphaned embeddings
    func cleanup() async {
        do {
            let allMemories = try await memoryRepository.getAll()
            let existingIds = Set(allMemories.map { $0.id })
            vectorSearchEngine.cleanup(existingMemoryIds: existingIds)
        } catch {
            // Ignore cleanup errors
        }
    }

    // MARK: - Statistics

    func getIndexStats() -> EmbeddingStats {
        return vectorSearchEngine.getStats()
    }

    // MARK: - Private Helpers

    private func performKeywordSearch(query: String) async -> Result<[SemanticSearchResult], Error> {
        do {
            let memories = try await memoryRepository.search(query: query)
            let results = memories.map { memory in
                SemanticSearchResult(
                    memory: memory,
                    similarity: 0.7, // Base score for keyword matches
                    matchType: .keyword
                )
            }
            return .success(results)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Models

struct SemanticSearchResult: Identifiable, Equatable {
    let memory: Memory
    let similarity: Float
    let matchType: MatchType

    var id: String { memory.id }

    /// Similarity as percentage (0-100)
    var similarityPercent: Int {
        Int(similarity * 100)
    }

    enum MatchType: String {
        case semantic   // Found by vector similarity
        case keyword    // Found by keyword search
        case hybrid     // Found by both methods
    }

    static func == (lhs: SemanticSearchResult, rhs: SemanticSearchResult) -> Bool {
        lhs.memory.id == rhs.memory.id && lhs.similarity == rhs.similarity
    }
}
