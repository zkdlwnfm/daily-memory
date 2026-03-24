import Foundation

/// Use case for updating an existing person.
final class UpdatePersonUseCase {
    private let personRepository: PersonRepository

    init(personRepository: PersonRepository = PersonRepositoryImpl()) {
        self.personRepository = personRepository
    }

    func execute(_ person: Person) async throws -> Person {
        try await personRepository.update(person)
        return person
    }
}
