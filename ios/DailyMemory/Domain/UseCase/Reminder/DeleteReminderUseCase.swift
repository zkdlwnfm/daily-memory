import Foundation

/// Use case for deleting a reminder.
final class DeleteReminderUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute(reminderId: String) async throws {
        try await reminderRepository.delete(id: reminderId)
        await SyncManager.shared.enqueueReminderChange(id: reminderId, type: .delete)
    }
}
