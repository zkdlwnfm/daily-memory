import Foundation

/// Use case for getting upcoming reminders.
final class GetUpcomingRemindersUseCase {
    private let reminderRepository: ReminderRepository

    init(reminderRepository: ReminderRepository = ReminderRepositoryImpl()) {
        self.reminderRepository = reminderRepository
    }

    func execute(limit: Int = 5) async throws -> [Reminder] {
        return try await reminderRepository.getUpcoming(from: Date(), limit: limit)
    }
}
