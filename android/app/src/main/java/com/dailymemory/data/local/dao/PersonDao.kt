package com.dailymemory.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dailymemory.data.local.entity.PersonEntity
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.model.SyncStatus
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

@Dao
interface PersonDao {

    // Insert
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(person: PersonEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(persons: List<PersonEntity>)

    // Update
    @Update
    suspend fun update(person: PersonEntity)

    // Delete
    @Delete
    suspend fun delete(person: PersonEntity)

    @Query("DELETE FROM persons WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM persons")
    suspend fun deleteAll()

    // Query - Single
    @Query("SELECT * FROM persons WHERE id = :id")
    suspend fun getById(id: String): PersonEntity?

    @Query("SELECT * FROM persons WHERE id = :id")
    fun observeById(id: String): Flow<PersonEntity?>

    // Query - All
    @Query("SELECT * FROM persons ORDER BY name ASC")
    fun observeAll(): Flow<List<PersonEntity>>

    @Query("SELECT * FROM persons ORDER BY CASE WHEN lastMeetingDate IS NULL THEN 1 ELSE 0 END, lastMeetingDate DESC")
    fun observeAllByLastMeeting(): Flow<List<PersonEntity>>

    @Query("SELECT * FROM persons ORDER BY meetingCount DESC")
    fun observeAllByMeetingCount(): Flow<List<PersonEntity>>

    // Query - By Relationship
    @Query("SELECT * FROM persons WHERE relationship = :relationship ORDER BY name ASC")
    fun observeByRelationship(relationship: Relationship): Flow<List<PersonEntity>>

    // Query - Search
    @Query("SELECT * FROM persons WHERE name LIKE '%' || :query || '%' OR nickname LIKE '%' || :query || '%' ORDER BY name ASC")
    fun searchByName(query: String): Flow<List<PersonEntity>>

    // Query - By Sync Status
    @Query("SELECT * FROM persons WHERE syncStatus = :status")
    suspend fun getBySyncStatus(status: SyncStatus): List<PersonEntity>

    @Query("SELECT * FROM persons WHERE syncStatus != :status")
    suspend fun getUnsyncedPersons(status: SyncStatus = SyncStatus.SYNCED): List<PersonEntity>

    // Query - Recently Met
    @Query("SELECT * FROM persons WHERE lastMeetingDate IS NOT NULL ORDER BY lastMeetingDate DESC LIMIT :limit")
    fun observeRecentlyMet(limit: Int): Flow<List<PersonEntity>>

    // Query - Not contacted for N days
    @Query("SELECT * FROM persons WHERE lastMeetingDate < :sinceDate OR lastMeetingDate IS NULL ORDER BY lastMeetingDate ASC")
    fun observeNotContactedSince(sinceDate: LocalDateTime): Flow<List<PersonEntity>>

    // Count
    @Query("SELECT COUNT(*) FROM persons")
    suspend fun getCount(): Int

    // Update Statistics
    @Query("UPDATE persons SET meetingCount = meetingCount + 1, lastMeetingDate = :date, updatedAt = :updatedAt WHERE id = :id")
    suspend fun incrementMeetingCount(id: String, date: LocalDateTime, updatedAt: LocalDateTime = LocalDateTime.now())

    // Update Sync Status
    @Query("UPDATE persons SET syncStatus = :status, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateSyncStatus(id: String, status: SyncStatus, updatedAt: LocalDateTime = LocalDateTime.now())
}
