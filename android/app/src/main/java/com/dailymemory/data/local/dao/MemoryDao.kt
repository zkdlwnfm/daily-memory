package com.dailymemory.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dailymemory.data.local.entity.MemoryEntity
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.SyncStatus
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

@Dao
interface MemoryDao {

    // Insert
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(memory: MemoryEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(memories: List<MemoryEntity>)

    // Update
    @Update
    suspend fun update(memory: MemoryEntity)

    // Delete
    @Delete
    suspend fun delete(memory: MemoryEntity)

    @Query("DELETE FROM memories WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM memories")
    suspend fun deleteAll()

    // Query - Single
    @Query("SELECT * FROM memories WHERE id = :id")
    suspend fun getById(id: String): MemoryEntity?

    @Query("SELECT * FROM memories WHERE id = :id")
    fun observeById(id: String): Flow<MemoryEntity?>

    // Query - All
    @Query("SELECT * FROM memories ORDER BY recordedAt DESC")
    fun observeAll(): Flow<List<MemoryEntity>>

    @Query("SELECT * FROM memories ORDER BY recordedAt DESC LIMIT :limit")
    fun observeRecent(limit: Int): Flow<List<MemoryEntity>>

    // Query - By Date Range
    @Query("SELECT * FROM memories WHERE recordedAt BETWEEN :start AND :end ORDER BY recordedAt DESC")
    fun observeByDateRange(start: LocalDateTime, end: LocalDateTime): Flow<List<MemoryEntity>>

    @Query("SELECT * FROM memories WHERE DATE(recordedAt) = DATE(:date) ORDER BY recordedAt DESC")
    fun observeByDate(date: LocalDateTime): Flow<List<MemoryEntity>>

    // Query - By Category
    @Query("SELECT * FROM memories WHERE category = :category ORDER BY recordedAt DESC")
    fun observeByCategory(category: Category): Flow<List<MemoryEntity>>

    // Query - By Person
    @Query("SELECT * FROM memories WHERE personIds LIKE '%' || :personId || '%' ORDER BY recordedAt DESC")
    fun observeByPersonId(personId: String): Flow<List<MemoryEntity>>

    // Query - Search
    @Query("SELECT * FROM memories WHERE content LIKE '%' || :query || '%' ORDER BY recordedAt DESC")
    fun searchByContent(query: String): Flow<List<MemoryEntity>>

    // Query - By Sync Status
    @Query("SELECT * FROM memories WHERE syncStatus = :status")
    suspend fun getBySyncStatus(status: SyncStatus): List<MemoryEntity>

    @Query("SELECT * FROM memories WHERE syncStatus != :status")
    suspend fun getUnsyncedMemories(status: SyncStatus = SyncStatus.SYNCED): List<MemoryEntity>

    // Query - Locked
    @Query("SELECT * FROM memories WHERE isLocked = 1 ORDER BY recordedAt DESC")
    fun observeLockedMemories(): Flow<List<MemoryEntity>>

    // Query - For AI (not excluded)
    @Query("SELECT * FROM memories WHERE excludeFromAI = 0 ORDER BY recordedAt DESC")
    fun observeForAI(): Flow<List<MemoryEntity>>

    // Count
    @Query("SELECT COUNT(*) FROM memories")
    suspend fun getCount(): Int

    @Query("SELECT COUNT(*) FROM memories WHERE DATE(recordedAt) = DATE(:date)")
    suspend fun getCountByDate(date: LocalDateTime): Int

    // Update Sync Status
    @Query("UPDATE memories SET syncStatus = :status, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateSyncStatus(id: String, status: SyncStatus, updatedAt: LocalDateTime = LocalDateTime.now())
}
