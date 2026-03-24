package com.dailymemory.domain.usecase.memory

import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.repository.MemoryRepository
import com.dailymemory.domain.repository.PersonRepository
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Use case for saving a new memory.
 * Handles the business logic of creating a memory and updating related persons.
 */
class SaveMemoryUseCase @Inject constructor(
    private val memoryRepository: MemoryRepository,
    private val personRepository: PersonRepository
) {
    suspend operator fun invoke(memory: Memory): Result<Memory> {
        return try {
            // Save the memory
            memoryRepository.insert(memory)

            // Update meeting count for related persons
            memory.personIds.forEach { personId ->
                personRepository.incrementMeetingCount(personId, memory.recordedAt)
            }

            Result.success(memory)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
