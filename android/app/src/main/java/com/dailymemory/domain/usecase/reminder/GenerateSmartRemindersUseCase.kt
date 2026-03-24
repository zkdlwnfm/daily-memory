package com.dailymemory.domain.usecase.reminder

import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.model.RepeatType
import com.dailymemory.domain.repository.PersonRepository
import kotlinx.coroutines.flow.first
import java.time.LocalDateTime
import java.time.LocalTime
import javax.inject.Inject

/**
 * Use case for generating smart reminder suggestions based on memories and AI analysis
 */
class GenerateSmartRemindersUseCase @Inject constructor(
    private val personRepository: PersonRepository
) {
    /**
     * Generate reminder suggestions based on a memory's content and extracted data
     */
    suspend operator fun invoke(memory: Memory): List<ReminderSuggestion> {
        val suggestions = mutableListOf<ReminderSuggestion>()

        // Check for event keywords
        val content = memory.content.lowercase()

        // Wedding detection
        if (content.contains("wedding")) {
            memory.extractedDate?.let { eventDate ->
                suggestions.add(
                    ReminderSuggestion(
                        type = SuggestionType.EVENT,
                        title = "Wedding Reminder",
                        body = "Don't forget about the wedding!",
                        suggestedDate = eventDate.minusDays(1).with(LocalTime.of(9, 0)),
                        reason = "Detected wedding event in your memory"
                    )
                )
            }
        }

        // Birthday detection
        if (content.contains("birthday")) {
            val personName = memory.extractedPersons.firstOrNull()
            if (personName != null) {
                memory.extractedDate?.let { eventDate ->
                    suggestions.add(
                        ReminderSuggestion(
                            type = SuggestionType.BIRTHDAY,
                            title = "$personName's Birthday",
                            body = "Don't forget to wish $personName a happy birthday!",
                            suggestedDate = eventDate.with(LocalTime.of(9, 0)),
                            repeatType = RepeatType.YEARLY,
                            reason = "Detected birthday mention"
                        )
                    )
                }
            }
        }

        // Meeting detection
        if (content.contains("meeting") || content.contains("call") || content.contains("appointment")) {
            memory.extractedDate?.let { eventDate ->
                suggestions.add(
                    ReminderSuggestion(
                        type = SuggestionType.MEETING,
                        title = "Meeting Reminder",
                        body = memory.content.take(100),
                        suggestedDate = eventDate.minusHours(1),
                        reason = "Detected upcoming meeting"
                    )
                )
            }
        }

        // Payment/Financial detection
        if (content.contains("pay") || content.contains("owe") || content.contains("lend") ||
            content.contains("borrow") || memory.extractedAmount != null) {
            val amount = memory.extractedAmount?.let { " ($${String.format("%.2f", it)})" } ?: ""
            val personName = memory.extractedPersons.firstOrNull() ?: "someone"

            suggestions.add(
                ReminderSuggestion(
                    type = SuggestionType.FINANCIAL,
                    title = "Payment Reminder",
                    body = "Remember the financial matter with $personName$amount",
                    suggestedDate = LocalDateTime.now().plusDays(7).with(LocalTime.of(10, 0)),
                    reason = "Detected financial transaction"
                )
            )
        }

        // Promise detection
        if (content.contains("promise") || content.contains("need to") ||
            content.contains("have to") || content.contains("should")) {
            suggestions.add(
                ReminderSuggestion(
                    type = SuggestionType.PROMISE,
                    title = "Follow Up",
                    body = memory.content.take(100),
                    suggestedDate = LocalDateTime.now().plusDays(3).with(LocalTime.of(9, 0)),
                    reason = "Detected promise or task"
                )
            )
        }

        return suggestions
    }

    /**
     * Generate birthday reminders for all persons with birthdays
     * Note: Birthday feature requires Person model to have birthday field
     */
    suspend fun generateBirthdayReminders(): List<Reminder> {
        // TODO: Implement when birthday field is added to Person model
        return emptyList()
    }
}

/**
 * A suggested reminder based on AI analysis
 */
data class ReminderSuggestion(
    val type: SuggestionType,
    val title: String,
    val body: String,
    val suggestedDate: LocalDateTime,
    val repeatType: RepeatType = RepeatType.NONE,
    val reason: String
) {
    fun toReminder(memoryId: String? = null, personId: String? = null): Reminder {
        return Reminder(
            memoryId = memoryId,
            personId = personId,
            title = title,
            body = body,
            scheduledAt = suggestedDate,
            repeatType = repeatType,
            isActive = true,
            isAutoGenerated = true
        )
    }
}

enum class SuggestionType {
    EVENT,
    BIRTHDAY,
    MEETING,
    FINANCIAL,
    PROMISE
}
