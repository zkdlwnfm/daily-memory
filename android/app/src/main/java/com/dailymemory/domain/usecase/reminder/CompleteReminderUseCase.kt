package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.repository.ReminderRepository
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Use case for marking a reminder as complete (triggered).
 */
class CompleteReminderUseCase @Inject constructor(
    private val reminderRepository: ReminderRepository
) {
    suspend operator fun invoke(reminderId: String): Result<Unit> {
        return try {
            reminderRepository.markAsTriggered(reminderId, LocalDateTime.now())
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
