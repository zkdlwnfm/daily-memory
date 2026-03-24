import Foundation

/// Use case for deleting a memory.
/// Also handles cleanup of related reminders.
final class DeleteMemoryUseCase {
    private let memoryRepository: MemoryRepository
    private let reminderRepository: ReminderRepository

    init(
        memoryRepository: MemoryRepository = MemoryRepositoryImpl(),
        reminderRepository: ReminderRepository = ReminderRepositoryImpl()
    ) {
        self.memoryRepository = memoryRepository
        self.reminderRepository = reminderRepository
    }

    func execute(memoryId: String) async throws {
        // Delete related reminders first
        let relatedReminders = try await reminderRepository.getByMemoryId(memoryId)
        for reminder in relatedReminders {
            try await reminderRepository.delete(id: reminder.id)
        }

        // Delete the memory
        try await memoryRepository.delete(id: memoryId)
    }
}
