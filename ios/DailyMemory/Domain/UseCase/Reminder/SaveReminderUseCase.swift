import Foundation

/// Use case for saving a new reminder.
final class SaveReminderUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute(_ reminder: Reminder) async throws -> Reminder {
        try await reminderRepository.save(reminder)
        return reminder
    }
}
