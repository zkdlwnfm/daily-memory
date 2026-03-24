package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.repository.ReminderRepository
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Use case for getting upcoming reminders.
 */
class GetUpcomingRemindersUseCase @Inject constructor(
    private val reminderRepository: ReminderRepository
) {
    operator fun invoke(limit: Int = 5): Flow<List<Reminder>> {
        return reminderRepository.observeUpcoming(LocalDateTime.now(), limit)
    }
}
