import Foundation

/// Use case for updating an existing reminder.
final class UpdateReminderUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute(_ reminder: Reminder) async throws -> Reminder {
        try await reminderRepository.update(reminder)
        await SyncManager.shared.enqueueReminderChange(id: reminder.id, type: .update)
        return reminder
    }
}
