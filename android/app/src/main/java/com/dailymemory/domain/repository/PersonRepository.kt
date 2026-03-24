package com.dailymemory.domain.repository

import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.model.SyncStatus
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * Repository interface for Person operations.
 * Defines the contract for data access, implemented in data layer.
 */
interface PersonRepository {

    // CRUD Operations
    suspend fun insert(person: Person)
    suspend fun update(person: Person)
    suspend fun delete(person: Person)
    suspend fun deleteById(id: String)

    // Query - Single
    suspend fun getById(id: String): Person?
    fun observeById(id: String): Flow<Person?>

    // Query - All (with different sorting)
    fun observeAll(): Flow<List<Person>>
    fun observeAllByLastMeeting(): Flow<List<Person>>
    fun observeAllByMeetingCount(): Flow<List<Person>>

    // Query - By Relationship
    fun observeByRelationship(relationship: Relationship): Flow<List<Person>>

    // Query - Search
    fun searchByName(query: String): Flow<List<Person>>

    // Query - Recently Met
    fun observeRecentlyMet(limit: Int): Flow<List<Person>>

    // Query - Not Contacted
    fun observeNotContactedSince(sinceDate: LocalDateTime): Flow<List<Person>>

    // Query - Sync
    suspend fun getUnsyncedPersons(): List<Person>
    suspend fun updateSyncStatus(id: String, status: SyncStatus)

    // Statistics
    suspend fun getCount(): Int
    suspend fun incrementMeetingCount(id: String, date: LocalDateTime)
}
