package com.dailymemory.domain.usecase.memory

import com.dailymemory.domain.repository.MemoryRepository
import com.dailymemory.domain.repository.ReminderRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Use case for deleting a memory.
 * Also handles cleanup of related reminders.
 */
class DeleteMemoryUseCase @Inject constructor(
    private val memoryRepository: MemoryRepository,
    private val reminderRepository: ReminderRepository
) {
    suspend operator fun invoke(memoryId: String): Result<Unit> {
        return try {
            // Delete related reminders first
            val relatedReminders = reminderRepository.observeByMemoryId(memoryId).first()
            relatedReminders.forEach { reminder ->
                reminderRepository.deleteById(reminder.id)
            }

            // Delete the memory
            memoryRepository.deleteById(memoryId)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
