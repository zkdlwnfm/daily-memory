package com.dailymemory.data.local

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

/**
 * Engine for vector similarity search using cosine similarity
 * Stores and searches embeddings for memories
 */
@Singleton
class VectorSearchEngine @Inject constructor(
    @ApplicationContext private val context: Context
) {
    // Storage
    private val memoryEmbeddings = mutableMapOf<String, FloatArray>() // memoryId -> embedding
    private val embeddingsFile: File
        get() = File(context.filesDir, "vector_embeddings.json")

    // Configuration
    private val similarityThreshold = 0.5f
    private val maxResults = 20

    init {
        loadEmbeddings()
    }

    // MARK: - Embedding Management

    /**
     * Store embedding for a memory
     */
    fun storeEmbedding(embedding: FloatArray, memoryId: String) {
        memoryEmbeddings[memoryId] = embedding
        saveEmbeddings()
    }

    /**
     * Store multiple embeddings
     */
    fun storeEmbeddings(embeddings: List<Pair<String, FloatArray>>) {
        embeddings.forEach { (memoryId, embedding) ->
            memoryEmbeddings[memoryId] = embedding
        }
        saveEmbeddings()
    }

    /**
     * Remove embedding for a memory
     */
    fun removeEmbedding(memoryId: String) {
        memoryEmbeddings.remove(memoryId)
        saveEmbeddings()
    }

    /**
     * Check if memory has embedding
     */
    fun hasEmbedding(memoryId: String): Boolean {
        return memoryEmbeddings.containsKey(memoryId)
    }

    /**
     * Get embedding for a memory
     */
    fun getEmbedding(memoryId: String): FloatArray? {
        return memoryEmbeddings[memoryId]
    }

    /**
     * Get all memory IDs with embeddings
     */
    fun getAllMemoryIds(): List<String> {
        return memoryEmbeddings.keys.toList()
    }

    // MARK: - Search

    /**
     * Search for similar memories using query embedding
     * Returns memory IDs sorted by similarity (highest first)
     */
    fun search(
        queryEmbedding: FloatArray,
        limit: Int = maxResults,
        threshold: Float = similarityThreshold
    ): List<SearchResult> {
        val results = mutableListOf<SearchResult>()

        for ((memoryId, embedding) in memoryEmbeddings) {
            val similarity = cosineSimilarity(queryEmbedding, embedding)

            if (similarity >= threshold) {
                results.add(SearchResult(memoryId = memoryId, similarity = similarity))
            }
        }

        // Sort by similarity descending and limit
        return results
            .sortedByDescending { it.similarity }
            .take(limit)
    }

    /**
     * Search excluding specific memory IDs
     */
    fun search(
        queryEmbedding: FloatArray,
        excludedIds: Set<String>,
        limit: Int = maxResults,
        threshold: Float = similarityThreshold
    ): List<SearchResult> {
        val results = mutableListOf<SearchResult>()

        for ((memoryId, embedding) in memoryEmbeddings) {
            if (memoryId in excludedIds) continue

            val similarity = cosineSimilarity(queryEmbedding, embedding)

            if (similarity >= threshold) {
                results.add(SearchResult(memoryId = memoryId, similarity = similarity))
            }
        }

        return results
            .sortedByDescending { it.similarity }
            .take(limit)
    }

    // MARK: - Similarity Calculation

    /**
     * Calculate cosine similarity between two vectors
     */
    fun cosineSimilarity(a: FloatArray, b: FloatArray): Float {
        if (a.size != b.size || a.isEmpty()) return 0f

        var dotProduct = 0f
        var magnitudeA = 0f
        var magnitudeB = 0f

        for (i in a.indices) {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }

        val magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)

        return if (magnitude > 0) dotProduct / magnitude else 0f
    }

    /**
     * Calculate Euclidean distance between two vectors
     */
    fun euclideanDistance(a: FloatArray, b: FloatArray): Float {
        if (a.size != b.size) return Float.MAX_VALUE

        var sumSquared = 0f
        for (i in a.indices) {
            val diff = a[i] - b[i]
            sumSquared += diff * diff
        }

        return sqrt(sumSquared)
    }

    // MARK: - Persistence

    private fun saveEmbeddings() {
        Thread {
            try {
                val json = JSONObject()

                for ((memoryId, embedding) in memoryEmbeddings) {
                    val embeddingArray = embedding.map { it.toDouble() }
                    json.put(memoryId, org.json.JSONArray(embeddingArray))
                }

                embeddingsFile.writeText(json.toString())
            } catch (e: Exception) {
                // Log error but don't crash
                e.printStackTrace()
            }
        }.start()
    }

    private fun loadEmbeddings() {
        try {
            if (!embeddingsFile.exists()) return

            val jsonString = embeddingsFile.readText()
            val json = JSONObject(jsonString)

            val keys = json.keys()
            while (keys.hasNext()) {
                val memoryId = keys.next()
                val embeddingArray = json.getJSONArray(memoryId)

                val floatArray = FloatArray(embeddingArray.length()) { i ->
                    embeddingArray.getDouble(i).toFloat()
                }

                memoryEmbeddings[memoryId] = floatArray
            }
        } catch (e: Exception) {
            // Log error but don't crash
            e.printStackTrace()
        }
    }

    // MARK: - Maintenance

    /**
     * Clear all embeddings
     */
    fun clearAll() {
        memoryEmbeddings.clear()
        embeddingsFile.delete()
    }

    /**
     * Get storage statistics
     */
    fun getStats(): EmbeddingStats {
        val count = memoryEmbeddings.size
        val dimensions = memoryEmbeddings.values.firstOrNull()?.size ?: 0
        val estimatedSizeBytes = count * dimensions * 4 // Float = 4 bytes

        return EmbeddingStats(
            count = count,
            dimensions = dimensions,
            estimatedSizeBytes = estimatedSizeBytes
        )
    }

    /**
     * Remove embeddings for memories that no longer exist
     */
    fun cleanup(existingMemoryIds: Set<String>) {
        val idsToRemove = memoryEmbeddings.keys.toSet() - existingMemoryIds

        if (idsToRemove.isNotEmpty()) {
            idsToRemove.forEach { memoryEmbeddings.remove(it) }
            saveEmbeddings()
        }
    }
}

// MARK: - Models

data class SearchResult(
    val memoryId: String,
    val similarity: Float
) {
    /**
     * Similarity as percentage (0-100)
     */
    val similarityPercent: Int
        get() = (similarity * 100).toInt()
}

data class EmbeddingStats(
    val count: Int,
    val dimensions: Int,
    val estimatedSizeBytes: Int
) {
    val formattedSize: String
        get() {
            return when {
                estimatedSizeBytes < 1024 -> "$estimatedSizeBytes B"
                estimatedSizeBytes < 1024 * 1024 -> "${estimatedSizeBytes / 1024} KB"
                else -> "${estimatedSizeBytes / (1024 * 1024)} MB"
            }
        }
}
