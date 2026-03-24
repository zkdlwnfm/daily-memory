import Foundation

/// Use case for snoozing a reminder.
/// Creates a new scheduled time by adding the specified minutes.
final class SnoozeReminderUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute(reminderId: String, snoozeMinutes: Int = 30) async throws {
        guard let reminder = try await reminderRepository.getById(reminderId) else {
            throw SnoozeError.reminderNotFound
        }

        let newScheduledTime = Calendar.current.date(
            byAdding: .minute,
            value: snoozeMinutes,
            to: Date()
        )!

        var updatedReminder = reminder
        updatedReminder.scheduledAt = newScheduledTime
        updatedReminder.triggeredAt = nil

        try await reminderRepository.update(updatedReminder)
    }

    enum SnoozeError: Error {
        case reminderNotFound
    }
}
