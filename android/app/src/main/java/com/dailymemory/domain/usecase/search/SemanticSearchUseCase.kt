package com.dailymemory.domain.usecase.search

import com.dailymemory.data.local.VectorSearchEngine
import com.dailymemory.data.remote.EmbeddingService
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.repository.MemoryRepository
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Use case for semantic (AI-powered) search of memories
 * Combines vector similarity search with traditional keyword search
 */
class SemanticSearchUseCase @Inject constructor(
    private val embeddingService: EmbeddingService,
    private val vectorSearchEngine: VectorSearchEngine,
    private val memoryRepository: MemoryRepository
) {
    // MARK: - Search

    /**
     * Perform semantic search with natural language query
     */
    suspend operator fun invoke(query: String, limit: Int = 20): Result<List<SemanticSearchResult>> {
        return embeddingService.generateEmbedding(query).mapCatching { queryEmbedding ->
            // Search for similar memories
            val searchResults = vectorSearchEngine.search(
                queryEmbedding = queryEmbedding,
                limit = limit,
                threshold = 0.4f // Lower threshold for more results
            )

            // Fetch actual memories
            val semanticResults = mutableListOf<SemanticSearchResult>()

            for (result in searchResults) {
                try {
                    val memory = memoryRepository.getById(result.memoryId)
                    if (memory != null) {
                        semanticResults.add(
                            SemanticSearchResult(
                                memory = memory,
                                similarity = result.similarity,
                                matchType = MatchType.SEMANTIC
                            )
                        )
                    }
                } catch (e: Exception) {
                    // Skip memories that can't be fetched
                    continue
                }
            }

            semanticResults
        }
    }

    /**
     * Perform hybrid search (semantic + keyword)
     */
    suspend fun searchHybrid(query: String, limit: Int = 20): Result<List<SemanticSearchResult>> = coroutineScope {
        val semanticDeferred = async { invoke(query, limit) }
        val keywordDeferred = async { performKeywordSearch(query) }

        val semanticResult = semanticDeferred.await()
        val keywordResult = keywordDeferred.await()

        // Merge results
        val resultMap = mutableMapOf<String, SemanticSearchResult>()

        // Add semantic results
        semanticResult.getOrNull()?.forEach { result ->
            resultMap[result.memory.id] = result
        }

        // Add/merge keyword results
        keywordResult.getOrNull()?.forEach { result ->
            val existing = resultMap[result.memory.id]
            if (existing != null) {
                // Boost score for memories found by both methods
                resultMap[result.memory.id] = SemanticSearchResult(
                    memory = result.memory,
                    similarity = minOf(existing.similarity + 0.2f, 1.0f),
                    matchType = MatchType.HYBRID
                )
            } else {
                resultMap[result.memory.id] = result
            }
        }

        // Sort by similarity and limit
        val sortedResults = resultMap.values
            .sortedByDescending { it.similarity }
            .take(limit)

        Result.success(sortedResults)
    }

    // MARK: - Embedding Management

    /**
     * Generate and store embedding for a memory
     */
    suspend fun indexMemory(memory: Memory) {
        embeddingService.generateEmbedding(memory.content).onSuccess { embedding ->
            vectorSearchEngine.storeEmbedding(embedding, memory.id)
        }
    }

    /**
     * Generate and store embeddings for multiple memories
     */
    suspend fun indexMemories(memories: List<Memory>) {
        val texts = memories.map { it.content }
        embeddingService.generateEmbeddings(texts).onSuccess { embeddings ->
            val pairs = memories.zip(embeddings).map { (memory, embedding) ->
                memory.id to embedding
            }
            vectorSearchEngine.storeEmbeddings(pairs)
        }
    }

    /**
     * Remove embedding when memory is deleted
     */
    fun removeIndex(memoryId: String) {
        vectorSearchEngine.removeEmbedding(memoryId)
    }

    /**
     * Check if memory is indexed
     */
    fun isIndexed(memoryId: String): Boolean {
        return vectorSearchEngine.hasEmbedding(memoryId)
    }

    /**
     * Index all unindexed memories
     */
    suspend fun indexAllUnindexed(): Int {
        return try {
            val allMemories = memoryRepository.getAll().first()
            val unindexedMemories = allMemories.filter { !vectorSearchEngine.hasEmbedding(it.id) }

            if (unindexedMemories.isEmpty()) return 0

            // Index in batches of 20
            val batchSize = 20
            var indexedCount = 0

            unindexedMemories.chunked(batchSize).forEach { batch ->
                indexMemories(batch)
                indexedCount += batch.size
            }

            indexedCount
        } catch (e: Exception) {
            0
        }
    }

    /**
     * Cleanup orphaned embeddings
     */
    suspend fun cleanup() {
        try {
            val allMemories = memoryRepository.getAll().first()
            val existingIds = allMemories.map { it.id }.toSet()
            vectorSearchEngine.cleanup(existingIds)
        } catch (e: Exception) {
            // Ignore cleanup errors
        }
    }

    // MARK: - Statistics

    fun getIndexStats() = vectorSearchEngine.getStats()

    // MARK: - Private Helpers

    private suspend fun performKeywordSearch(query: String): Result<List<SemanticSearchResult>> {
        return try {
            val memories = memoryRepository.search(query).first()
            val results = memories.map { memory ->
                SemanticSearchResult(
                    memory = memory,
                    similarity = 0.7f, // Base score for keyword matches
                    matchType = MatchType.KEYWORD
                )
            }
            Result.success(results)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

// MARK: - Models

data class SemanticSearchResult(
    val memory: Memory,
    val similarity: Float,
    val matchType: MatchType
) {
    /**
     * Similarity as percentage (0-100)
     */
    val similarityPercent: Int
        get() = (similarity * 100).toInt()
}

enum class MatchType {
    SEMANTIC,   // Found by vector similarity
    KEYWORD,    // Found by keyword search
    HYBRID      // Found by both methods
}
