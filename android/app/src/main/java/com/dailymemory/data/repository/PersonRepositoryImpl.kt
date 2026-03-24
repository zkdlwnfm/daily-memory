package com.dailymemory.data.repository

import com.dailymemory.data.local.dao.PersonDao
import com.dailymemory.data.local.entity.PersonEntity
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.model.SyncStatus
import com.dailymemory.domain.repository.PersonRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of PersonRepository.
 * Handles data operations using Room DAO.
 */
@Singleton
class PersonRepositoryImpl @Inject constructor(
    private val personDao: PersonDao
) : PersonRepository {

    // CRUD Operations
    override suspend fun insert(person: Person) {
        personDao.insert(PersonEntity.fromDomainModel(person))
    }

    override suspend fun update(person: Person) {
        personDao.update(PersonEntity.fromDomainModel(person.copy(updatedAt = LocalDateTime.now())))
    }

    override suspend fun delete(person: Person) {
        personDao.delete(PersonEntity.fromDomainModel(person))
    }

    override suspend fun deleteById(id: String) {
        personDao.deleteById(id)
    }

    // Query - Single
    override suspend fun getById(id: String): Person? {
        return personDao.getById(id)?.toDomainModel()
    }

    override fun observeById(id: String): Flow<Person?> {
        return personDao.observeById(id).map { it?.toDomainModel() }
    }

    // Query - All (with different sorting)
    override fun observeAll(): Flow<List<Person>> {
        return personDao.observeAll().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun observeAllByLastMeeting(): Flow<List<Person>> {
        return personDao.observeAllByLastMeeting().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun observeAllByMeetingCount(): Flow<List<Person>> {
        return personDao.observeAllByMeetingCount().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - By Relationship
    override fun observeByRelationship(relationship: Relationship): Flow<List<Person>> {
        return personDao.observeByRelationship(relationship).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - Search
    override fun searchByName(query: String): Flow<List<Person>> {
        return personDao.searchByName(query).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - Recently Met
    override fun observeRecentlyMet(limit: Int): Flow<List<Person>> {
        return personDao.observeRecentlyMet(limit).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - Not Contacted
    override fun observeNotContactedSince(sinceDate: LocalDateTime): Flow<List<Person>> {
        return personDao.observeNotContactedSince(sinceDate).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // Query - Sync
    override suspend fun getUnsyncedPersons(): List<Person> {
        return personDao.getUnsyncedPersons().map { it.toDomainModel() }
    }

    override suspend fun updateSyncStatus(id: String, status: SyncStatus) {
        personDao.updateSyncStatus(id, status)
    }

    // Statistics
    override suspend fun getCount(): Int {
        return personDao.getCount()
    }

    override suspend fun incrementMeetingCount(id: String, date: LocalDateTime) {
        personDao.incrementMeetingCount(id, date)
    }
}
