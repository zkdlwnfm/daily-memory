import Foundation

/// Use case for saving a new person.
final class SavePersonUseCase {
    private let personRepository: PersonRepository

    init(personRepository: PersonRepository = PersonRepositoryImpl()) {
        self.personRepository = personRepository
    }

    func execute(_ person: Person) async throws -> Person {
        try await personRepository.save(person)
        await SyncManager.shared.enqueuePersonChange(id: person.id, type: .create)
        return person
    }
}
