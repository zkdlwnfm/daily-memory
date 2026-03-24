import Foundation

/// Use case for marking a reminder as complete (triggered).
final class CompleteReminderUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute(reminderId: String) async throws {
        try await reminderRepository.markAsTriggered(id: reminderId)
    }
}
