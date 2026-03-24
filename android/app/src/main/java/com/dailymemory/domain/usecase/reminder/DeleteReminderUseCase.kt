package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.repository.ReminderRepository
import javax.inject.Inject

/**
 * Use case for deleting a reminder.
 */
class DeleteReminderUseCase @Inject constructor(
    private val reminderRepository: ReminderRepository
) {
    suspend operator fun invoke(reminderId: String): Result<Unit> {
        return try {
            reminderRepository.deleteById(reminderId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
