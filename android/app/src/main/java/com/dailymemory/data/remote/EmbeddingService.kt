package com.dailymemory.data.remote

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

/**
 * Service for generating text embeddings using OpenAI API
 * Uses text-embedding-3-small model for cost-effective semantic search
 */
@Singleton
class EmbeddingService @Inject constructor() {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    // Configuration
    private var apiKey: String = ""
    private val model = "text-embedding-3-small"
    private val dimensions = 1536

    // Cache
    private val embeddingCache = mutableMapOf<String, FloatArray>()
    private val maxCacheSize = 1000

    /**
     * Configure the service with OpenAI API key
     */
    fun configure(apiKey: String) {
        this.apiKey = apiKey
    }

    /**
     * Generate embedding for a single text
     */
    suspend fun generateEmbedding(text: String): Result<FloatArray> = withContext(Dispatchers.IO) {
        // Check cache first
        val cacheKey = text.take(200).lowercase()
        embeddingCache[cacheKey]?.let {
            return@withContext Result.success(it)
        }

        if (apiKey.isEmpty()) {
            return@withContext Result.success(simulateEmbedding(text))
        }

        try {
            val embedding = fetchEmbedding(text)

            // Cache the result
            if (embeddingCache.size >= maxCacheSize) {
                embeddingCache.clear()
            }
            embeddingCache[cacheKey] = embedding

            Result.success(embedding)
        } catch (e: Exception) {
            // Fallback to simulation on error
            Result.success(simulateEmbedding(text))
        }
    }

    /**
     * Generate embeddings for multiple texts (batch)
     */
    suspend fun generateEmbeddings(texts: List<String>): Result<List<FloatArray>> = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) {
            return@withContext Result.success(texts.map { simulateEmbedding(it) })
        }

        try {
            val embeddings = fetchEmbeddings(texts)
            Result.success(embeddings)
        } catch (e: Exception) {
            Result.success(texts.map { simulateEmbedding(it) })
        }
    }

    private fun fetchEmbedding(text: String): FloatArray {
        return fetchEmbeddings(listOf(text)).first()
    }

    private fun fetchEmbeddings(texts: List<String>): List<FloatArray> {
        val requestBody = JSONObject().apply {
            put("model", model)
            put("input", JSONArray(texts))
            put("dimensions", dimensions)
        }.toString()

        val request = Request.Builder()
            .url("https://api.openai.com/v1/embeddings")
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer $apiKey")
            .post(requestBody.toRequestBody("application/json".toMediaType()))
            .build()

        val response = client.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw EmbeddingException("Empty response")

        if (!response.isSuccessful) {
            throw EmbeddingException("API error: HTTP ${response.code}")
        }

        return parseEmbeddingResponse(responseBody)
    }

    private fun parseEmbeddingResponse(responseBody: String): List<FloatArray> {
        val json = JSONObject(responseBody)
        val dataArray = json.getJSONArray("data")

        // Parse and sort by index
        val embeddings = mutableListOf<Pair<Int, FloatArray>>()

        for (i in 0 until dataArray.length()) {
            val item = dataArray.getJSONObject(i)
            val index = item.getInt("index")
            val embeddingArray = item.getJSONArray("embedding")

            val floatArray = FloatArray(embeddingArray.length()) { j ->
                embeddingArray.getDouble(j).toFloat()
            }

            embeddings.add(index to floatArray)
        }

        return embeddings.sortedBy { it.first }.map { it.second }
    }

    /**
     * Simulate embedding for testing/demo purposes
     */
    private fun simulateEmbedding(text: String): FloatArray {
        val embedding = FloatArray(dimensions) { 0f }
        val words = text.lowercase().split(" ")

        words.forEachIndexed { index, word ->
            val hash = word.hashCode()
            val position = kotlin.math.abs(hash) % dimensions

            // Distribute word influence across multiple dimensions
            for (offset in 0 until 10) {
                val idx = (position + offset) % dimensions
                val value = (hash % 1000) / 1000f * (if (index % 2 == 0) 1 else -1)
                embedding[idx] += value / words.size
            }
        }

        // Normalize the vector
        val magnitude = sqrt(embedding.sumOf { (it * it).toDouble() }).toFloat()
        if (magnitude > 0) {
            for (i in embedding.indices) {
                embedding[i] /= magnitude
            }
        }

        return embedding
    }

    /**
     * Clear the embedding cache
     */
    fun clearCache() {
        embeddingCache.clear()
    }

    /**
     * Get current cache size
     */
    fun getCacheSize(): Int = embeddingCache.size
}

/**
 * Exception for embedding errors
 */
class EmbeddingException(message: String) : Exception(message)
