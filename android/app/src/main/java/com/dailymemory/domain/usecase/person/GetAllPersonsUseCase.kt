package com.dailymemory.domain.usecase.person

import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.repository.PersonRepository
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Use case for getting all persons with various sorting options.
 */
class GetAllPersonsUseCase @Inject constructor(
    private val personRepository: PersonRepository
) {
    enum class SortOrder {
        ALPHABETICAL,
        RECENT_MEETING,
        MOST_FREQUENT
    }

    operator fun invoke(sortOrder: SortOrder = SortOrder.ALPHABETICAL): Flow<List<Person>> {
        return when (sortOrder) {
            SortOrder.ALPHABETICAL -> personRepository.observeAll()
            SortOrder.RECENT_MEETING -> personRepository.observeAllByLastMeeting()
            SortOrder.MOST_FREQUENT -> personRepository.observeAllByMeetingCount()
        }
    }

    fun byRelationship(relationship: Relationship): Flow<List<Person>> {
        return personRepository.observeByRelationship(relationship)
    }

    fun search(query: String): Flow<List<Person>> {
        return personRepository.searchByName(query)
    }

    fun recentlyMet(limit: Int = 5): Flow<List<Person>> {
        return personRepository.observeRecentlyMet(limit)
    }

    fun notContactedSince(days: Int): Flow<List<Person>> {
        val sinceDate = LocalDateTime.now().minusDays(days.toLong())
        return personRepository.observeNotContactedSince(sinceDate)
    }
}
