package com.dailymemory.domain.usecase.ai

import com.dailymemory.data.remote.AIAnalysisService
import com.dailymemory.data.remote.AnalysisResult
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject

/**
 * Use case for analyzing memory text with AI
 * Extracts entities like people, locations, dates, and amounts
 */
class AnalyzeMemoryUseCase @Inject constructor(
    private val aiAnalysisService: AIAnalysisService
) {
    /**
     * Analyze text and return extracted entities
     */
    suspend operator fun invoke(text: String): Result<MemoryAnalysis> {
        return aiAnalysisService.analyzeText(text).map { result ->
            result.toMemoryAnalysis()
        }
    }

    /**
     * Analyze and create a Memory object with extracted data
     */
    suspend fun analyzeAndCreateMemory(
        content: String,
        latitude: Double? = null,
        longitude: Double? = null
    ): Result<Memory> {
        return aiAnalysisService.analyzeText(content).map { result ->
            val analysis = result.toMemoryAnalysis()

            Memory(
                content = content,
                extractedPersons = analysis.persons,
                extractedLocation = analysis.location,
                extractedDate = analysis.date,
                extractedAmount = analysis.amount,
                extractedTags = analysis.tags,
                category = analysis.category,
                recordedAt = LocalDateTime.now(),
                recordedLatitude = latitude,
                recordedLongitude = longitude
            )
        }
    }
}

/**
 * Data class for memory analysis results
 */
data class MemoryAnalysis(
    val persons: List<String>,
    val location: String?,
    val date: LocalDateTime?,
    val amount: Double?,
    val tags: List<String>,
    val category: Category,
    val summary: String
)

/**
 * Extension to convert API result to domain model
 */
private fun AnalysisResult.toMemoryAnalysis(): MemoryAnalysis {
    // Parse date if present
    val parsedDate = date?.let {
        try {
            LocalDateTime.parse(it, DateTimeFormatter.ISO_DATE_TIME)
        } catch (e: Exception) {
            try {
                LocalDateTime.parse(it + "T00:00:00", DateTimeFormatter.ISO_DATE_TIME)
            } catch (e: Exception) {
                null
            }
        }
    }

    // Parse category
    val parsedCategory = try {
        Category.valueOf(category.uppercase())
    } catch (e: Exception) {
        Category.GENERAL
    }

    return MemoryAnalysis(
        persons = persons,
        location = location,
        date = parsedDate,
        amount = amount,
        tags = tags,
        category = parsedCategory,
        summary = summary
    )
}
