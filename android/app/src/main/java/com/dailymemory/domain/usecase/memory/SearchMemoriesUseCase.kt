package com.dailymemory.domain.usecase.memory

import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.repository.MemoryRepository
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Use case for searching memories with various filters.
 */
class SearchMemoriesUseCase @Inject constructor(
    private val memoryRepository: MemoryRepository
) {
    // Main invoke operator for simple search
    operator fun invoke(query: String): Flow<List<Memory>> {
        return memoryRepository.searchByContent(query)
    }

    // Search by content
    fun byContent(query: String): Flow<List<Memory>> {
        return memoryRepository.searchByContent(query)
    }

    // Search by category
    fun byCategory(category: Category): Flow<List<Memory>> {
        return memoryRepository.observeByCategory(category)
    }

    // Search by date range
    fun byDateRange(start: LocalDateTime, end: LocalDateTime): Flow<List<Memory>> {
        return memoryRepository.observeByDateRange(start, end)
    }

    // Search by specific date
    fun byDate(date: LocalDateTime): Flow<List<Memory>> {
        return memoryRepository.observeByDate(date)
    }

    // Search by person
    fun byPerson(personId: String): Flow<List<Memory>> {
        return memoryRepository.observeByPersonId(personId)
    }
}
