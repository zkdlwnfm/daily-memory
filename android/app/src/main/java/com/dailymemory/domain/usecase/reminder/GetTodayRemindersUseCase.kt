package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.repository.ReminderRepository
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Use case for getting today's reminders.
 */
class GetTodayRemindersUseCase @Inject constructor(
    private val reminderRepository: ReminderRepository
) {
    operator fun invoke(): Flow<List<Reminder>> {
        return reminderRepository.observeByDate(LocalDateTime.now())
    }
}
