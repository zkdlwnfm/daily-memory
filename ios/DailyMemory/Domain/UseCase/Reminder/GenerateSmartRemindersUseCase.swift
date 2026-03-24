import Foundation

/// Use case for generating smart reminder suggestions based on memories and AI analysis
final class GenerateSmartRemindersUseCase {
    private let personRepository: PersonRepository

    init(personRepository: PersonRepository = PersonRepositoryImpl()) {
        self.personRepository = personRepository
    }

    /// Generate reminder suggestions based on a memory's content and extracted data
    func execute(memory: Memory) -> [ReminderSuggestion] {
        var suggestions: [ReminderSuggestion] = []
        let content = memory.content.lowercased()

        // Wedding detection
        if content.contains("wedding") {
            if let eventDate = memory.extractedDate {
                let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: eventDate) ?? eventDate
                suggestions.append(
                    ReminderSuggestion(
                        type: .event,
                        title: "Wedding Reminder",
                        body: "Don't forget about the wedding!",
                        suggestedDate: setTime(reminderDate, hour: 9, minute: 0),
                        repeatType: .none,
                        reason: "Detected wedding event in your memory"
                    )
                )
            }
        }

        // Birthday detection
        if content.contains("birthday") {
            let personName = memory.extractedPersons.first
            if let personName = personName, let eventDate = memory.extractedDate {
                suggestions.append(
                    ReminderSuggestion(
                        type: .birthday,
                        title: "\(personName)'s Birthday",
                        body: "Don't forget to wish \(personName) a happy birthday!",
                        suggestedDate: setTime(eventDate, hour: 9, minute: 0),
                        repeatType: .yearly,
                        reason: "Detected birthday mention"
                    )
                )
            }
        }

        // Meeting detection
        if content.contains("meeting") || content.contains("call") || content.contains("appointment") {
            if let eventDate = memory.extractedDate {
                let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: eventDate) ?? eventDate
                suggestions.append(
                    ReminderSuggestion(
                        type: .meeting,
                        title: "Meeting Reminder",
                        body: String(memory.content.prefix(100)),
                        suggestedDate: reminderDate,
                        repeatType: .none,
                        reason: "Detected upcoming meeting"
                    )
                )
            }
        }

        // Payment/Financial detection
        if content.contains("pay") || content.contains("owe") || content.contains("lend") ||
           content.contains("borrow") || memory.extractedAmount != nil {
            let amount = memory.extractedAmount.map { String(format: " ($%.2f)", $0) } ?? ""
            let personName = memory.extractedPersons.first ?? "someone"

            let reminderDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            suggestions.append(
                ReminderSuggestion(
                    type: .financial,
                    title: "Payment Reminder",
                    body: "Remember the financial matter with \(personName)\(amount)",
                    suggestedDate: setTime(reminderDate, hour: 10, minute: 0),
                    repeatType: .none,
                    reason: "Detected financial transaction"
                )
            )
        }

        // Promise detection
        if content.contains("promise") || content.contains("need to") ||
           content.contains("have to") || content.contains("should") {
            let reminderDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            suggestions.append(
                ReminderSuggestion(
                    type: .promise,
                    title: "Follow Up",
                    body: String(memory.content.prefix(100)),
                    suggestedDate: setTime(reminderDate, hour: 9, minute: 0),
                    repeatType: .none,
                    reason: "Detected promise or task"
                )
            )
        }

        return suggestions
    }

    /// Generate birthday reminders for all persons with birthdays
    /// Note: Requires birthday field to be added to Person model
    func generateBirthdayReminders() async throws -> [Reminder] {
        // TODO: Implement when birthday field is added to Person model
        return []
    }

    private func setTime(_ date: Date, hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? date
    }
}

/// A suggested reminder based on AI analysis
struct ReminderSuggestion {
    let type: SuggestionType
    let title: String
    let body: String
    let suggestedDate: Date
    let repeatType: RepeatType
    let reason: String

    func toReminder(memoryId: String? = nil, personId: String? = nil) -> Reminder {
        Reminder(
            memoryId: memoryId,
            personId: personId,
            title: title,
            body: body,
            scheduledAt: suggestedDate,
            repeatType: repeatType,
            isActive: true,
            isAutoGenerated: true
        )
    }
}

enum SuggestionType {
    case event
    case birthday
    case meeting
    case financial
    case promise
}
