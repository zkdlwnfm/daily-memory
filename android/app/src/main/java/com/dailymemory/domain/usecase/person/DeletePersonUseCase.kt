package com.dailymemory.domain.usecase.person

import com.dailymemory.domain.repository.PersonRepository
import com.dailymemory.domain.repository.ReminderRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Use case for deleting a person.
 * Also handles cleanup of related reminders.
 */
class DeletePersonUseCase @Inject constructor(
    private val personRepository: PersonRepository,
    private val reminderRepository: ReminderRepository
) {
    suspend operator fun invoke(personId: String): Result<Unit> {
        return try {
            // Delete related reminders first
            val relatedReminders = reminderRepository.observeByPersonId(personId).first()
            relatedReminders.forEach { reminder ->
                reminderRepository.deleteById(reminder.id)
            }

            // Delete the person
            personRepository.deleteById(personId)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
