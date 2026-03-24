package com.dailymemory.domain.model

import java.time.LocalDateTime
import java.util.UUID

/**
 * Domain model for Memory (기록)
 */
data class Memory(
    val id: String = UUID.randomUUID().toString(),
    val content: String,

    // Photos
    val photos: List<Photo> = emptyList(),

    // AI Extracted Data
    val extractedPersons: List<String> = emptyList(),
    val extractedLocation: String? = null,
    val extractedDate: LocalDateTime? = null,
    val extractedAmount: Double? = null,
    val extractedTags: List<String> = emptyList(),

    // User Confirmed Data
    val personIds: List<String> = emptyList(),
    val category: Category = Category.GENERAL,
    val importance: Int = 3, // 1-5

    // Security
    val isLocked: Boolean = false,
    val excludeFromAI: Boolean = false,

    // Embedding (for vector search)
    val embedding: List<Float>? = null,

    // Metadata
    val recordedAt: LocalDateTime = LocalDateTime.now(),
    val recordedLatitude: Double? = null,
    val recordedLongitude: Double? = null,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    val syncStatus: SyncStatus = SyncStatus.PENDING
)

/**
 * Photo attachment
 */
data class Photo(
    val id: String = UUID.randomUUID().toString(),
    val url: String,
    val thumbnailUrl: String? = null,
    val aiAnalysis: String? = null,
    val createdAt: LocalDateTime = LocalDateTime.now()
)

/**
 * Memory category
 */
enum class Category {
    EVENT,      // 이벤트, 기념일
    PROMISE,    // 약속, 할 일
    MEETING,    // 미팅, 만남
    FINANCIAL,  // 금전 관계
    GENERAL;    // 일반 기록

    companion object {
        fun fromString(value: String): Category {
            return try {
                valueOf(value.uppercase())
            } catch (e: IllegalArgumentException) {
                GENERAL
            }
        }
    }
}

/**
 * Sync status for offline-first architecture
 */
enum class SyncStatus {
    SYNCED,     // Synced with cloud
    PENDING,    // Waiting to be synced
    CONFLICT,   // Sync conflict detected
    LOCAL_ONLY  // Local only (privacy mode)
}
