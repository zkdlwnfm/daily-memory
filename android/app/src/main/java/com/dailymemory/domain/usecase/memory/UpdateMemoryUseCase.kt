package com.dailymemory.domain.usecase.memory

import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.repository.MemoryRepository
import javax.inject.Inject

/**
 * Use case for updating an existing memory.
 */
class UpdateMemoryUseCase @Inject constructor(
    private val memoryRepository: MemoryRepository
) {
    suspend operator fun invoke(memory: Memory): Result<Memory> {
        return try {
            memoryRepository.update(memory)
            Result.success(memory)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
