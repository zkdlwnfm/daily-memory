package com.dailymemory.domain.repository

import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.SyncStatus
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * Repository interface for Memory operations.
 * Defines the contract for data access, implemented in data layer.
 */
interface MemoryRepository {

    // CRUD Operations
    suspend fun insert(memory: Memory)
    suspend fun update(memory: Memory)
    suspend fun delete(memory: Memory)
    suspend fun deleteById(id: String)

    // Query - Single
    suspend fun getById(id: String): Memory?
    fun observeById(id: String): Flow<Memory?>

    // Query - All
    fun observeAll(): Flow<List<Memory>>
    fun observeRecent(limit: Int): Flow<List<Memory>>

    // Query - By Date
    fun observeByDateRange(start: LocalDateTime, end: LocalDateTime): Flow<List<Memory>>
    fun observeByDate(date: LocalDateTime): Flow<List<Memory>>

    // Query - By Category
    fun observeByCategory(category: Category): Flow<List<Memory>>

    // Query - By Person
    fun observeByPersonId(personId: String): Flow<List<Memory>>

    // Query - Search
    fun searchByContent(query: String): Flow<List<Memory>>

    // Query - Sync
    suspend fun getUnsyncedMemories(): List<Memory>
    suspend fun updateSyncStatus(id: String, status: SyncStatus)

    // Query - Security
    fun observeLockedMemories(): Flow<List<Memory>>
    fun observeForAI(): Flow<List<Memory>>

    // Statistics
    suspend fun getCount(): Int
    suspend fun getCountByDate(date: LocalDateTime): Int
}
