import Foundation

/// Use case for getting today's reminders.
final class GetTodayRemindersUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute() async throws -> [Reminder] {
        return try await reminderRepository.getByDate(Date())
    }
}
