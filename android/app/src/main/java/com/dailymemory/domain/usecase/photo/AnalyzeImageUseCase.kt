package com.dailymemory.domain.usecase.photo

import android.graphics.Bitmap
import android.net.Uri
import com.dailymemory.data.remote.ImageAnalysisResult
import com.dailymemory.data.remote.ImageAnalysisService
import java.io.File
import javax.inject.Inject

/**
 * Use case for analyzing images with AI
 * Extracts objects, scenes, text, and generates tags
 */
class AnalyzeImageUseCase @Inject constructor(
    private val imageAnalysisService: ImageAnalysisService
) {
    /**
     * Analyze a single bitmap and return results
     */
    suspend operator fun invoke(bitmap: Bitmap): Result<PhotoAnalysis> {
        return imageAnalysisService.analyzeImage(bitmap).map { result ->
            result.toPhotoAnalysis()
        }
    }

    /**
     * Analyze image from URI
     */
    suspend fun analyze(uri: Uri): Result<PhotoAnalysis> {
        return imageAnalysisService.analyzeImage(uri).map { result ->
            result.toPhotoAnalysis()
        }
    }

    /**
     * Analyze image from file
     */
    suspend fun analyze(file: File): Result<PhotoAnalysis> {
        return imageAnalysisService.analyzeImage(file).map { result ->
            result.toPhotoAnalysis()
        }
    }

    /**
     * Analyze multiple bitmaps and return individual results
     */
    suspend fun analyzeMultiple(bitmaps: List<Bitmap>): Result<List<PhotoAnalysis>> {
        val results = mutableListOf<PhotoAnalysis>()

        for (bitmap in bitmaps) {
            val result = imageAnalysisService.analyzeImage(bitmap)
            result.onSuccess { analysisResult ->
                results.add(analysisResult.toPhotoAnalysis())
            }.onFailure { error ->
                return Result.failure(error)
            }
        }

        return Result.success(results)
    }

    /**
     * Analyze multiple bitmaps and merge into combined analysis
     */
    suspend fun analyzeAndMerge(bitmaps: List<Bitmap>): Result<CombinedPhotoAnalysis> {
        return analyzeMultiple(bitmaps).map { analyses ->
            CombinedPhotoAnalysis.merge(analyses)
        }
    }
}

/**
 * Analysis result for a single photo
 */
data class PhotoAnalysis(
    val objects: List<String>,
    val scene: String,
    val ocrText: String?,
    val faceCount: Int,
    val description: String,
    val suggestedTags: List<String>
) {
    /**
     * Check if people were detected
     */
    val hasPeople: Boolean
        get() = faceCount > 0 || objects.any { it.lowercase().contains("person") }

    /**
     * Check if text was detected
     */
    val hasText: Boolean
        get() = !ocrText.isNullOrEmpty()
}

/**
 * Combined analysis from multiple photos
 */
data class CombinedPhotoAnalysis(
    val allObjects: List<String>,
    val scenes: List<String>,
    val allOcrText: List<String>,
    val totalFaces: Int,
    val descriptions: List<String>,
    val mergedTags: List<String>
) {
    companion object {
        /**
         * Merge multiple photo analyses into one
         */
        fun merge(analyses: List<PhotoAnalysis>): CombinedPhotoAnalysis {
            val allObjects = mutableSetOf<String>()
            val scenes = mutableListOf<String>()
            val allOcrText = mutableListOf<String>()
            var totalFaces = 0
            val descriptions = mutableListOf<String>()
            val allTags = mutableSetOf<String>()

            for (analysis in analyses) {
                allObjects.addAll(analysis.objects)
                scenes.add(analysis.scene)
                analysis.ocrText?.takeIf { it.isNotEmpty() }?.let { allOcrText.add(it) }
                totalFaces += analysis.faceCount
                descriptions.add(analysis.description)
                allTags.addAll(analysis.suggestedTags)
            }

            return CombinedPhotoAnalysis(
                allObjects = allObjects.toList().sorted(),
                scenes = scenes,
                allOcrText = allOcrText,
                totalFaces = totalFaces,
                descriptions = descriptions,
                mergedTags = allTags.toList().sorted()
            )
        }
    }
}

/**
 * Extension to convert API result to domain model
 */
private fun ImageAnalysisResult.toPhotoAnalysis(): PhotoAnalysis {
    return PhotoAnalysis(
        objects = objects,
        scene = scene,
        ocrText = text,
        faceCount = faces,
        description = description,
        suggestedTags = suggestedTags
    )
}
