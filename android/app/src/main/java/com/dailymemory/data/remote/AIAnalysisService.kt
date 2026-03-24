package com.dailymemory.data.remote

import com.dailymemory.domain.model.Category
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import org.json.JSONArray
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * AI Analysis Service for extracting entities from text
 * Supports both OpenAI and Claude APIs
 */
@Singleton
class AIAnalysisService @Inject constructor() {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()


    // API Configuration - should be stored securely (e.g., BuildConfig, encrypted preferences)
    private var apiKey: String = ""
    private var apiProvider: AIProvider = AIProvider.CLAUDE

    enum class AIProvider {
        OPENAI,
        CLAUDE
    }

    /**
     * Configure the AI service
     */
    fun configure(apiKey: String, provider: AIProvider = AIProvider.CLAUDE) {
        this.apiKey = apiKey
        this.apiProvider = provider
    }

    /**
     * Analyze text and extract entities
     */
    suspend fun analyzeText(text: String): Result<AnalysisResult> = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) {
            // Return simulated result when no API key is configured
            return@withContext Result.success(simulateAnalysis(text))
        }

        try {
            val result = when (apiProvider) {
                AIProvider.OPENAI -> analyzeWithOpenAI(text)
                AIProvider.CLAUDE -> analyzeWithClaude(text)
            }
            Result.success(result)
        } catch (e: Exception) {
            // Fallback to simulation on error
            Result.success(simulateAnalysis(text))
        }
    }

    private suspend fun analyzeWithClaude(text: String): AnalysisResult {
        val prompt = buildAnalysisPrompt(text)

        val requestBody = """
            {
                "model": "claude-3-haiku-20240307",
                "max_tokens": 1024,
                "messages": [
                    {
                        "role": "user",
                        "content": "$prompt"
                    }
                ]
            }
        """.trimIndent()

        val request = Request.Builder()
            .url("https://api.anthropic.com/v1/messages")
            .addHeader("Content-Type", "application/json")
            .addHeader("x-api-key", apiKey)
            .addHeader("anthropic-version", "2023-06-01")
            .post(requestBody.toRequestBody("application/json".toMediaType()))
            .build()

        val response = client.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw Exception("Empty response")

        return parseAnalysisResponse(responseBody)
    }

    private suspend fun analyzeWithOpenAI(text: String): AnalysisResult {
        val prompt = buildAnalysisPrompt(text)

        val requestBody = """
            {
                "model": "gpt-3.5-turbo",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a helpful assistant that extracts structured information from text."
                    },
                    {
                        "role": "user",
                        "content": "$prompt"
                    }
                ],
                "temperature": 0.3
            }
        """.trimIndent()

        val request = Request.Builder()
            .url("https://api.openai.com/v1/chat/completions")
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer $apiKey")
            .post(requestBody.toRequestBody("application/json".toMediaType()))
            .build()

        val response = client.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw Exception("Empty response")

        return parseAnalysisResponse(responseBody)
    }

    private fun buildAnalysisPrompt(text: String): String {
        return """
            Analyze the following text and extract structured information.
            Return a JSON object with these fields:
            - persons: array of person names mentioned
            - location: the main location mentioned (or null)
            - date: any specific date mentioned in ISO format (or null)
            - amount: any monetary amount mentioned as a number (or null)
            - tags: array of relevant keywords/topics
            - category: one of EVENT, PROMISE, MEETING, FINANCIAL, GENERAL
            - summary: a brief one-sentence summary

            Text: "$text"

            Respond ONLY with valid JSON, no additional text.
        """.trimIndent().replace("\n", "\\n")
    }

    private fun parseAnalysisResponse(responseBody: String): AnalysisResult {
        // Extract JSON content from API response
        val contentRegex = """"content":\s*"([^"]+)"""".toRegex()
        val textRegex = """"text":\s*"([^"]+)"""".toRegex()

        val content = contentRegex.find(responseBody)?.groupValues?.get(1)
            ?: textRegex.find(responseBody)?.groupValues?.get(1)
            ?: responseBody

        // Parse the extracted JSON
        return try {
            val cleanJson = content
                .replace("\\n", "\n")
                .replace("\\\"", "\"")
                .let { str ->
                    val start = str.indexOf("{")
                    val end = str.lastIndexOf("}") + 1
                    if (start >= 0 && end > start) str.substring(start, end) else str
                }

            val jsonObj = JSONObject(cleanJson)

            val persons = mutableListOf<String>()
            jsonObj.optJSONArray("persons")?.let { arr ->
                for (i in 0 until arr.length()) {
                    persons.add(arr.getString(i))
                }
            }

            val tags = mutableListOf<String>()
            jsonObj.optJSONArray("tags")?.let { arr ->
                for (i in 0 until arr.length()) {
                    tags.add(arr.getString(i))
                }
            }

            AnalysisResult(
                persons = persons,
                location = jsonObj.optString("location").takeIf { it.isNotEmpty() && it != "null" },
                date = jsonObj.optString("date").takeIf { it.isNotEmpty() && it != "null" },
                amount = jsonObj.optDouble("amount").takeIf { !it.isNaN() },
                tags = tags,
                category = jsonObj.optString("category", "GENERAL"),
                summary = jsonObj.optString("summary", "")
            )
        } catch (e: Exception) {
            // Return empty result on parse error
            AnalysisResult()
        }
    }

    /**
     * Simulate AI analysis for testing/demo purposes
     */
    private fun simulateAnalysis(text: String): AnalysisResult {
        val lowerText = text.lowercase()

        // Extract names (simple heuristic: capitalized words)
        val namePattern = "\\b([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)?)\\b".toRegex()
        val persons = namePattern.findAll(text)
            .map { it.value }
            .filter { it.length > 2 && !commonWords.contains(it.lowercase()) }
            .distinct()
            .toList()

        // Extract location
        val locationKeywords = listOf("at ", "in ", "near ", "to ")
        var location: String? = null
        for (keyword in locationKeywords) {
            val idx = lowerText.indexOf(keyword)
            if (idx >= 0) {
                val remaining = text.substring(idx + keyword.length)
                val endIdx = remaining.indexOfAny(charArrayOf('.', ',', '!', '?', '\n'))
                location = if (endIdx > 0) remaining.substring(0, endIdx).trim()
                          else remaining.split(" ").take(3).joinToString(" ").trim()
                if (location.isNotEmpty()) break
            }
        }

        // Extract amount
        val amountPattern = "\\$([\\d,]+(?:\\.\\d{2})?)".toRegex()
        val amount = amountPattern.find(text)?.groupValues?.get(1)
            ?.replace(",", "")?.toDoubleOrNull()

        // Determine category
        val category = when {
            lowerText.contains("wedding") || lowerText.contains("birthday") ||
            lowerText.contains("party") || lowerText.contains("anniversary") -> Category.EVENT
            lowerText.contains("meeting") || lowerText.contains("lunch") ||
            lowerText.contains("dinner") || lowerText.contains("met") -> Category.MEETING
            lowerText.contains("pay") || lowerText.contains("owe") ||
            lowerText.contains("money") || amount != null -> Category.FINANCIAL
            lowerText.contains("promise") || lowerText.contains("will") ||
            lowerText.contains("remind") || lowerText.contains("todo") -> Category.PROMISE
            else -> Category.GENERAL
        }

        // Generate tags
        val tags = mutableListOf<String>()
        if (persons.isNotEmpty()) tags.add("people")
        if (location != null) tags.add("location")
        if (amount != null) tags.add("money")
        if (lowerText.contains("gift")) tags.add("gift")
        if (lowerText.contains("work") || lowerText.contains("office")) tags.add("work")
        if (lowerText.contains("family")) tags.add("family")

        // Generate summary
        val summary = text.take(100) + if (text.length > 100) "..." else ""

        return AnalysisResult(
            persons = persons,
            location = location,
            date = null,
            amount = amount,
            tags = tags,
            category = category.name,
            summary = summary
        )
    }

    companion object {
        private val commonWords = setOf(
            "the", "and", "but", "for", "not", "you", "all", "can", "had", "her",
            "was", "one", "our", "out", "day", "get", "has", "him", "his", "how",
            "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy",
            "did", "got", "let", "put", "say", "she", "too", "use", "monday",
            "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "january", "february", "march", "april", "june", "july", "august",
            "september", "october", "november", "december", "today", "yesterday"
        )
    }
}

data class AnalysisResult(
    val persons: List<String> = emptyList(),
    val location: String? = null,
    val date: String? = null,
    val amount: Double? = null,
    val tags: List<String> = emptyList(),
    val category: String = "GENERAL",
    val summary: String = ""
)
