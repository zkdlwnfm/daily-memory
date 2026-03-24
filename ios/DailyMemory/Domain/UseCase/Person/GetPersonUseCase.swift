import Foundation

/// Use case for getting a single person by ID.
final class GetPersonUseCase {
    private let personRepository: PersonRepository

    init(personRepository: PersonRepository = PersonRepositoryImpl()) {
        self.personRepository = personRepository
    }

    func execute(id: String) async throws -> Person? {
        return try await personRepository.getById(id)
    }
}
