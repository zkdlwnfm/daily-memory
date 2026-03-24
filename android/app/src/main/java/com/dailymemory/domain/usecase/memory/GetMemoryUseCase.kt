package com.dailymemory.domain.usecase.memory

import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.repository.MemoryRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for getting a single memory by ID.
 */
class GetMemoryUseCase @Inject constructor(
    private val memoryRepository: MemoryRepository
) {
    suspend operator fun invoke(id: String): Memory? {
        return memoryRepository.getById(id)
    }

    fun observe(id: String): Flow<Memory?> {
        return memoryRepository.observeById(id)
    }
}
