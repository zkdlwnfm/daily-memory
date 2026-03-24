package com.dailymemory.domain.model

import java.time.LocalDateTime
import java.util.UUID

/**
 * Domain model for Person (인물)
 */
data class Person(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val nickname: String? = null,
    val relationship: Relationship = Relationship.OTHER,

    // Contact Info (optional)
    val phone: String? = null,
    val email: String? = null,

    // AI Generated Summary
    val summary: String? = null,

    // Statistics (auto-calculated)
    val meetingCount: Int = 0,
    val lastMeetingDate: LocalDateTime? = null,

    // Profile
    val profileImageUrl: String? = null,
    val memo: String? = null,

    // Metadata
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    val syncStatus: SyncStatus = SyncStatus.PENDING
)

/**
 * Relationship type
 */
enum class Relationship {
    FAMILY,         // 가족
    FRIEND,         // 친구
    COLLEAGUE,      // 동료
    BUSINESS,       // 비즈니스
    ACQUAINTANCE,   // 지인
    OTHER;          // 기타

    companion object {
        fun fromString(value: String): Relationship {
            return try {
                valueOf(value.uppercase())
            } catch (e: IllegalArgumentException) {
                OTHER
            }
        }
    }

    fun getDisplayName(): String {
        return when (this) {
            FAMILY -> "Family"
            FRIEND -> "Friend"
            COLLEAGUE -> "Colleague"
            BUSINESS -> "Business"
            ACQUAINTANCE -> "Acquaintance"
            OTHER -> "Other"
        }
    }
}
