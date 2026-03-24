package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.repository.ReminderRepository
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import javax.inject.Inject

/**
 * Use case for snoozing a reminder.
 * Creates a new scheduled time by adding the specified minutes.
 */
class SnoozeReminderUseCase @Inject constructor(
    private val reminderRepository: ReminderRepository
) {
    suspend operator fun invoke(reminderId: String, snoozeMinutes: Int = 30): Result<Unit> {
        return try {
            val reminder = reminderRepository.getById(reminderId)
                ?: return Result.failure(IllegalArgumentException("Reminder not found"))

            val newScheduledTime = LocalDateTime.now().plus(snoozeMinutes.toLong(), ChronoUnit.MINUTES)

            reminderRepository.update(
                reminder.copy(
                    scheduledAt = newScheduledTime,
                    triggeredAt = null
                )
            )

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
