package com.dailymemory.domain.usecase.memory

import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.repository.MemoryRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for getting recent memories.
 */
class GetRecentMemoriesUseCase @Inject constructor(
    private val memoryRepository: MemoryRepository
) {
    operator fun invoke(limit: Int = 10): Flow<List<Memory>> {
        return memoryRepository.observeRecent(limit)
    }
}
