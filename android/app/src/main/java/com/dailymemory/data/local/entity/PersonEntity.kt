package com.dailymemory.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.dailymemory.data.local.converter.Converters
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.model.SyncStatus
import java.time.LocalDateTime

@Entity(tableName = "persons")
@TypeConverters(Converters::class)
data class PersonEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val nickname: String?,
    val relationship: Relationship,

    // Contact Info
    val phone: String?,
    val email: String?,

    // AI Summary
    val summary: String?,

    // Statistics
    val meetingCount: Int,
    val lastMeetingDate: LocalDateTime?,

    // Profile
    val profileImageUrl: String?,
    val memo: String?,

    // Metadata
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val syncStatus: SyncStatus
) {
    fun toDomainModel(): Person {
        return Person(
            id = id,
            name = name,
            nickname = nickname,
            relationship = relationship,
            phone = phone,
            email = email,
            summary = summary,
            meetingCount = meetingCount,
            lastMeetingDate = lastMeetingDate,
            profileImageUrl = profileImageUrl,
            memo = memo,
            createdAt = createdAt,
            updatedAt = updatedAt,
            syncStatus = syncStatus
        )
    }

    companion object {
        fun fromDomainModel(person: Person): PersonEntity {
            return PersonEntity(
                id = person.id,
                name = person.name,
                nickname = person.nickname,
                relationship = person.relationship,
                phone = person.phone,
                email = person.email,
                summary = person.summary,
                meetingCount = person.meetingCount,
                lastMeetingDate = person.lastMeetingDate,
                profileImageUrl = person.profileImageUrl,
                memo = person.memo,
                createdAt = person.createdAt,
                updatedAt = person.updatedAt,
                syncStatus = person.syncStatus
            )
        }
    }
}
