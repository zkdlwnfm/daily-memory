import Foundation

/// Use case for deleting a person.
/// Also handles cleanup of related reminders.
final class DeletePersonUseCase {
    private let personRepository: PersonRepository
    private let reminderRepository: ReminderRepository

    init(
        personRepository: PersonRepository = PersonRepositoryImpl(),
        reminderRepository: ReminderRepository = ReminderRepositoryImpl()
    ) {
        self.personRepository = personRepository
        self.reminderRepository = reminderRepository
    }

    func execute(personId: String) async throws {
        // Delete related reminders first
        let relatedReminders = try await reminderRepository.getByPersonId(personId)
        for reminder in relatedReminders {
            try await reminderRepository.delete(id: reminder.id)
        }

        // Delete the person
        try await personRepository.delete(id: personId)
        await SyncManager.shared.enqueuePersonChange(id: personId, type: .delete)
    }
}
