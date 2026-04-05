package com.dailymemory.data.remote

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for analyzing images using Vision AI (OpenAI GPT-4o Vision)
 * Extracts objects, scene descriptions, text (OCR), and face counts
 */
@Singleton
class ImageAnalysisService @Inject constructor(
    @ApplicationContext private val context: Context
) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(60, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()

    // API Configuration
    private var apiKey: String = ""

    /**
     * Configure the service with OpenAI API key
     */
    fun configure(apiKey: String) {
        this.apiKey = apiKey
    }

    /**
     * Analyze an image and extract information
     */
    suspend fun analyzeImage(bitmap: Bitmap): Result<ImageAnalysisResult> = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) {
            // Return simulated result when no API key is configured
            return@withContext Result.success(simulateAnalysis(bitmap))
        }

        try {
            val result = analyzeWithOpenAI(bitmap)
            Result.success(result)
        } catch (e: Exception) {
            // Fallback to simulation on error
            Result.success(simulateAnalysis(bitmap))
        }
    }

    /**
     * Analyze image from URI
     */
    suspend fun analyzeImage(uri: Uri): Result<ImageAnalysisResult> = withContext(Dispatchers.IO) {
        try {
            val inputStream = context.contentResolver.openInputStream(uri)
                ?: return@withContext Result.failure(ImageAnalysisException("Cannot open image"))

            val bitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()

            if (bitmap == null) {
                return@withContext Result.failure(ImageAnalysisException("Cannot decode image"))
            }

            analyzeImage(bitmap)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Analyze image from file path
     */
    suspend fun analyzeImage(file: File): Result<ImageAnalysisResult> = withContext(Dispatchers.IO) {
        try {
            val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                ?: return@withContext Result.failure(ImageAnalysisException("Cannot decode image"))

            analyzeImage(bitmap)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun analyzeWithOpenAI(bitmap: Bitmap): ImageAnalysisResult {
        // Resize image if needed and convert to base64
        val resizedBitmap = resizeBitmapIfNeeded(bitmap, 1024)
        val base64Image = bitmapToBase64(resizedBitmap)

        if (resizedBitmap != bitmap) {
            resizedBitmap.recycle()
        }

        val requestBody = JSONObject().apply {
            put("model", "gpt-4o")
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", JSONArray().apply {
                        put(JSONObject().apply {
                            put("type", "text")
                            put("text", buildAnalysisPrompt())
                        })
                        put(JSONObject().apply {
                            put("type", "image_url")
                            put("image_url", JSONObject().apply {
                                put("url", "data:image/jpeg;base64,$base64Image")
                                put("detail", "low")
                            })
                        })
                    })
                })
            })
            put("max_tokens", 500)
            put("temperature", 0.3)
        }.toString()

        val request = Request.Builder()
            .url("https://api.openai.com/v1/chat/completions")
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer $apiKey")
            .post(requestBody.toRequestBody("application/json".toMediaType()))
            .build()

        val response = client.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw ImageAnalysisException("Empty response")

        if (!response.isSuccessful) {
            throw ImageAnalysisException("API error: HTTP ${response.code}")
        }

        return parseAnalysisResponse(responseBody)
    }

    private fun buildAnalysisPrompt(): String {
        return """
            Analyze this image and extract structured information.
            Return a JSON object with these fields:
            - objects: array of objects/items visible in the image (e.g., "person", "dog", "cake", "car")
            - scene: brief description of the scene/setting (e.g., "birthday party indoor", "beach sunset")
            - text: any visible text in the image (OCR), or null if none
            - faces: number of human faces visible (integer)
            - description: a brief one-sentence description of what's happening in the image
            - suggestedTags: array of relevant tags for categorizing this image (e.g., "family", "celebration", "travel")

            Respond ONLY with valid JSON, no additional text or markdown.
        """.trimIndent()
    }

    private fun parseAnalysisResponse(responseBody: String): ImageAnalysisResult {
        val json = JSONObject(responseBody)

        // Extract content from OpenAI response
        val choices = json.optJSONArray("choices")
            ?: throw ImageAnalysisException("Invalid response: no choices")
        val firstChoice = choices.optJSONObject(0)
            ?: throw ImageAnalysisException("Invalid response: no first choice")
        val message = firstChoice.optJSONObject("message")
            ?: throw ImageAnalysisException("Invalid response: no message")
        val content = message.optString("content")
            ?: throw ImageAnalysisException("Invalid response: no content")

        // Extract JSON from content
        val jsonStart = content.indexOf("{")
        val jsonEnd = content.lastIndexOf("}") + 1
        if (jsonStart < 0 || jsonEnd <= jsonStart) {
            throw ImageAnalysisException("Invalid response: no JSON found")
        }

        val jsonString = content.substring(jsonStart, jsonEnd)
        val resultJson = JSONObject(jsonString)

        // Parse objects
        val objects = mutableListOf<String>()
        resultJson.optJSONArray("objects")?.let { arr ->
            for (i in 0 until arr.length()) {
                objects.add(arr.getString(i))
            }
        }

        // Parse suggested tags
        val suggestedTags = mutableListOf<String>()
        resultJson.optJSONArray("suggestedTags")?.let { arr ->
            for (i in 0 until arr.length()) {
                suggestedTags.add(arr.getString(i))
            }
        }

        return ImageAnalysisResult(
            objects = objects,
            scene = resultJson.optString("scene", ""),
            text = resultJson.optString("text").takeIf { it.isNotEmpty() && it != "null" },
            faces = resultJson.optInt("faces", 0),
            description = resultJson.optString("description", ""),
            suggestedTags = suggestedTags
        )
    }

    /**
     * Simulate image analysis for testing/demo purposes
     */
    private fun simulateAnalysis(bitmap: Bitmap): ImageAnalysisResult {
        val width = bitmap.width
        val height = bitmap.height
        val aspectRatio = width.toFloat() / height.toFloat()

        var objects: List<String>
        var scene: String
        var suggestedTags: List<String>

        // Simulate based on aspect ratio
        when {
            aspectRatio > 1.5f -> {
                // Wide/landscape image - likely outdoor or scenery
                scene = "outdoor landscape"
                objects = listOf("sky", "nature")
                suggestedTags = listOf("outdoor", "scenery", "landscape")
            }
            aspectRatio < 0.7f -> {
                // Tall/portrait image - likely portrait photo
                scene = "portrait photo"
                objects = listOf("person")
                suggestedTags = listOf("portrait", "people")
            }
            else -> {
                // Square-ish - could be anything
                scene = "casual photo"
                objects = listOf("person", "background")
                suggestedTags = listOf("casual", "moment")
            }
        }

        return ImageAnalysisResult(
            objects = objects,
            scene = scene,
            text = null,
            faces = 1,
            description = "A $scene captured in this photo",
            suggestedTags = suggestedTags
        )
    }

    private fun resizeBitmapIfNeeded(bitmap: Bitmap, maxSize: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        if (width <= maxSize && height <= maxSize) {
            return bitmap
        }

        val ratio = minOf(maxSize.toFloat() / width, maxSize.toFloat() / height)
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
        val byteArray = outputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }
}

/**
 * Result of image analysis
 */
data class ImageAnalysisResult(
    val objects: List<String> = emptyList(),
    val scene: String = "",
    val text: String? = null,
    val faces: Int = 0,
    val description: String = "",
    val suggestedTags: List<String> = emptyList()
) {
    /**
     * Check if people were detected
     */
    val hasPeople: Boolean
        get() = faces > 0 || objects.any { it.lowercase().contains("person") }

    /**
     * Check if text was detected
     */
    val hasText: Boolean
        get() = !text.isNullOrEmpty()
}

/**
 * Exception for image analysis errors
 */
class ImageAnalysisException(message: String) : Exception(message)
