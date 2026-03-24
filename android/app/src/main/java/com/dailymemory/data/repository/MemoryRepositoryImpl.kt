package com.dailymemory.data.repository

import com.dailymemory.data.local.dao.MemoryDao
import com.dailymemory.data.local.entity.MemoryEntity
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.SyncStatus
import com.dailymemory.domain.repository.MemoryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of MemoryRepository.
 * Handles data operations using Room DAO.
 */
@Singleton
class MemoryRepositoryImpl @Inject constructor(
    private val memoryDao: MemoryDao
) : MemoryRepository {

    // CRUD Operations
    override suspend fun insert(memory: Memory) {
        memoryDao.insert(MemoryEntity.fromDomainModel(memory))
    }

    override suspend fun update(memory: Memory) {
        memoryDao.update(MemoryEntity.fromDomainModel(memory.copy(updatedAt = LocalDateTime.now())))
    }

    override suspend fun delete(memory: Memory) {
        memoryDao.delete(MemoryEntity.fromDomainModel(memory))
    }

    override suspend fun deleteById(id: String) {
        memoryDao.deleteById(id)
    }

    // Query - Single
    override suspend fun getById(id: String): Memory? {
        return memoryDao.getById(id)?.toDomainModel()
    }

    override fun observeById(id: String): Flow<Memory?> {
        return memoryDao.observeById(id).map { it?.toDomainModel() }
    }

    // Query - All
    override fun observeAll(): Flow<List<Memory>> {
        return memoryDao.observeAll().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun observeRecent(limit: Int): Flow<List<Memory>> {
        return memoryDao.observeRecent(limit).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - By Date
    override fun observeByDateRange(start: LocalDateTime, end: LocalDateTime): Flow<List<Memory>> {
        return memoryDao.observeByDateRange(start, end).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun observeByDate(date: LocalDateTime): Flow<List<Memory>> {
        return memoryDao.observeByDate(date).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - By Category
    override fun observeByCategory(category: Category): Flow<List<Memory>> {
        return memoryDao.observeByCategory(category).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - By Person
    override fun observeByPersonId(personId: String): Flow<List<Memory>> {
        return memoryDao.observeByPersonId(personId).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - Search
    override fun searchByContent(query: String): Flow<List<Memory>> {
        return memoryDao.searchByContent(query).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - Sync
    override suspend fun getUnsyncedMemories(): List<Memory> {
        return memoryDao.getUnsyncedMemories().map { it.toDomainModel() }
    }

    override suspend fun updateSyncStatus(id: String, status: SyncStatus) {
        memoryDao.updateSyncStatus(id, status)
    }

    // Query - Security
    override fun observeLockedMemories(): Flow<List<Memory>> {
        return memoryDao.observeLockedMemories().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun observeForAI(): Flow<List<Memory>> {
        return memoryDao.observeForAI().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Statistics
    override suspend fun getCount(): Int {
        return memoryDao.getCount()
    }

    override suspend fun getCountByDate(date: LocalDateTime): Int {
        return memoryDao.getCountByDate(date)
    }
}
