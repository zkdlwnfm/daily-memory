package com.dailymemory.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.dailymemory.data.local.converter.Converters
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Photo
import com.dailymemory.domain.model.SyncStatus
import java.time.LocalDateTime

@Entity(tableName = "memories")
@TypeConverters(Converters::class)
data class MemoryEntity(
    @PrimaryKey
    val id: String,
    val content: String,

    // Photos (stored as JSON string)
    val photosJson: String,

    // AI Extracted Data
    val extractedPersons: List<String>,
    val extractedLocation: String?,
    val extractedDate: LocalDateTime?,
    val extractedAmount: Double?,
    val extractedTags: List<String>,

    // User Confirmed Data
    val personIds: List<String>,
    val category: Category,
    val importance: Int,

    // Security
    val isLocked: Boolean,
    val excludeFromAI: Boolean,

    // Embedding
    val embeddingJson: String?,

    // Metadata
    val recordedAt: LocalDateTime,
    val recordedLatitude: Double?,
    val recordedLongitude: Double?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val syncStatus: SyncStatus
) {
    fun toDomainModel(): Memory {
        return Memory(
            id = id,
            content = content,
            photos = Converters.jsonToPhotos(photosJson),
            extractedPersons = extractedPersons,
            extractedLocation = extractedLocation,
            extractedDate = extractedDate,
            extractedAmount = extractedAmount,
            extractedTags = extractedTags,
            personIds = personIds,
            category = category,
            importance = importance,
            isLocked = isLocked,
            excludeFromAI = excludeFromAI,
            embedding = embeddingJson?.let { Converters.jsonToFloatList(it) },
            recordedAt = recordedAt,
            recordedLatitude = recordedLatitude,
            recordedLongitude = recordedLongitude,
            createdAt = createdAt,
            updatedAt = updatedAt,
            syncStatus = syncStatus
        )
    }

    companion object {
        fun fromDomainModel(memory: Memory): MemoryEntity {
            return MemoryEntity(
                id = memory.id,
                content = memory.content,
                photosJson = Converters.photosToJson(memory.photos),
                extractedPersons = memory.extractedPersons,
                extractedLocation = memory.extractedLocation,
                extractedDate = memory.extractedDate,
                extractedAmount = memory.extractedAmount,
                extractedTags = memory.extractedTags,
                personIds = memory.personIds,
                category = memory.category,
                importance = memory.importance,
                isLocked = memory.isLocked,
                excludeFromAI = memory.excludeFromAI,
                embeddingJson = memory.embedding?.let { Converters.floatListToJson(it) },
                recordedAt = memory.recordedAt,
                recordedLatitude = memory.recordedLatitude,
                recordedLongitude = memory.recordedLongitude,
                createdAt = memory.createdAt,
                updatedAt = memory.updatedAt,
                syncStatus = memory.syncStatus
            )
        }
    }
}
