package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.repository.ReminderRepository
import javax.inject.Inject

/**
 * Use case for saving a new reminder.
 */
class SaveReminderUseCase @Inject constructor(
    private val reminderRepository: ReminderRepository
) {
    suspend operator fun invoke(reminder: Reminder): Result<Reminder> {
        return try {
            reminderRepository.insert(reminder)
            Result.success(reminder)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
