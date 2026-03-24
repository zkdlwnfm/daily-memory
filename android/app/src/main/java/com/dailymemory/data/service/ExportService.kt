package com.dailymemory.data.service

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileWriter
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ExportService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val exportDir: File
        get() = File(context.cacheDir, "exports").apply { mkdirs() }

    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME

    /**
     * Export memories to JSON format
     */
    suspend fun exportToJson(
        memories: List<Memory>,
        persons: List<Person> = emptyList()
    ): Result<ExportResult> = withContext(Dispatchers.IO) {
        try {
            val timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))
            val fileName = "dailymemory_export_$timestamp.json"
            val file = File(exportDir, fileName)

            val jsonObject = JSONObject().apply {
                put("exportDate", LocalDateTime.now().format(dateFormatter))
                put("version", "1.0")
                put("memoriesCount", memories.size)
                put("personsCount", persons.size)

                // Memories array
                put("memories", JSONArray().apply {
                    memories.forEach { memory ->
                        put(memoryToJson(memory))
                    }
                })

                // Persons array
                put("persons", JSONArray().apply {
                    persons.forEach { person ->
                        put(personToJson(person))
                    }
                })
            }

            FileWriter(file).use { writer ->
                writer.write(jsonObject.toString(2))
            }

            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            Result.success(ExportResult(
                uri = uri,
                fileName = fileName,
                mimeType = "application/json",
                itemCount = memories.size
            ))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Export memories to CSV format
     */
    suspend fun exportToCsv(memories: List<Memory>): Result<ExportResult> = withContext(Dispatchers.IO) {
        try {
            val timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))
            val fileName = "dailymemory_export_$timestamp.csv"
            val file = File(exportDir, fileName)

            FileWriter(file).use { writer ->
                // Write header
                writer.write("ID,Date,Time,Content,Category,Importance,Location,Amount,Persons,Tags,IsLocked\n")

                // Write data rows
                memories.forEach { memory ->
                    val row = buildString {
                        append(escapeCsv(memory.id))
                        append(",")
                        append(memory.recordedAt.format(DateTimeFormatter.ISO_LOCAL_DATE))
                        append(",")
                        append(memory.recordedAt.format(DateTimeFormatter.ofPattern("HH:mm:ss")))
                        append(",")
                        append(escapeCsv(memory.content))
                        append(",")
                        append(memory.category.name)
                        append(",")
                        append(memory.importance)
                        append(",")
                        append(escapeCsv(memory.extractedLocation ?: ""))
                        append(",")
                        append(memory.extractedAmount?.toString() ?: "")
                        append(",")
                        append(escapeCsv(memory.extractedPersons.joinToString("; ")))
                        append(",")
                        append(escapeCsv(memory.extractedTags.joinToString("; ")))
                        append(",")
                        append(memory.isLocked)
                        append("\n")
                    }
                    writer.write(row)
                }
            }

            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            Result.success(ExportResult(
                uri = uri,
                fileName = fileName,
                mimeType = "text/csv",
                itemCount = memories.size
            ))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Export memories for a specific date range
     */
    suspend fun exportDateRange(
        memories: List<Memory>,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        format: ExportFormat
    ): Result<ExportResult> {
        val filteredMemories = memories.filter { memory ->
            memory.recordedAt >= startDate && memory.recordedAt <= endDate
        }

        return when (format) {
            ExportFormat.JSON -> exportToJson(filteredMemories)
            ExportFormat.CSV -> exportToCsv(filteredMemories)
        }
    }

    /**
     * Create share intent for export file
     */
    fun createShareIntent(exportResult: ExportResult): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = exportResult.mimeType
            putExtra(Intent.EXTRA_STREAM, exportResult.uri)
            putExtra(Intent.EXTRA_SUBJECT, "DailyMemory Export - ${exportResult.fileName}")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    /**
     * Clean up old export files
     */
    fun cleanupExports() {
        exportDir.listFiles()?.forEach { file ->
            // Delete files older than 1 day
            if (System.currentTimeMillis() - file.lastModified() > 24 * 60 * 60 * 1000) {
                file.delete()
            }
        }
    }

    private fun memoryToJson(memory: Memory): JSONObject {
        return JSONObject().apply {
            put("id", memory.id)
            put("content", memory.content)
            put("category", memory.category.name)
            put("importance", memory.importance)
            put("isLocked", memory.isLocked)
            put("recordedAt", memory.recordedAt.format(dateFormatter))
            put("createdAt", memory.createdAt.format(dateFormatter))
            put("updatedAt", memory.updatedAt.format(dateFormatter))

            memory.extractedLocation?.let { put("extractedLocation", it) }
            memory.extractedAmount?.let { put("extractedAmount", it) }
            memory.recordedLatitude?.let { put("latitude", it) }
            memory.recordedLongitude?.let { put("longitude", it) }

            if (memory.extractedPersons.isNotEmpty()) {
                put("extractedPersons", JSONArray(memory.extractedPersons))
            }
            if (memory.extractedTags.isNotEmpty()) {
                put("extractedTags", JSONArray(memory.extractedTags))
            }
            if (memory.personIds.isNotEmpty()) {
                put("personIds", JSONArray(memory.personIds))
            }
            if (memory.photos.isNotEmpty()) {
                put("photos", JSONArray().apply {
                    memory.photos.forEach { photo ->
                        put(JSONObject().apply {
                            put("id", photo.id)
                            put("url", photo.url)
                            photo.thumbnailUrl?.let { put("thumbnailUrl", it) }
                            photo.aiAnalysis?.let { put("aiAnalysis", it) }
                        })
                    }
                })
            }
        }
    }

    private fun personToJson(person: Person): JSONObject {
        return JSONObject().apply {
            put("id", person.id)
            put("name", person.name)
            put("relationship", person.relationship.name)
            person.nickname?.let { put("nickname", it) }
            person.phone?.let { put("phone", it) }
            person.email?.let { put("email", it) }
            person.memo?.let { put("memo", it) }
            person.profileImageUrl?.let { put("profileImageUrl", it) }
        }
    }

    private fun escapeCsv(value: String): String {
        val needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n")
        return if (needsQuotes) {
            "\"${value.replace("\"", "\"\"")}\""
        } else {
            value
        }
    }
}

data class ExportResult(
    val uri: Uri,
    val fileName: String,
    val mimeType: String,
    val itemCount: Int
)

enum class ExportFormat {
    JSON,
    CSV
}
