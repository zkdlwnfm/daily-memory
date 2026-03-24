import Foundation

/// Use case for getting all persons with various sorting options.
final class GetAllPersonsUseCase {
    private let personRepository: PersonRepository

    init(personRepository: PersonRepository = PersonRepositoryImpl()) {
        self.personRepository = personRepository
    }

    func execute(sortedBy: PersonSortOrder = .alphabetical) async throws -> [Person] {
        return try await personRepository.getAll(sortedBy: sortedBy)
    }

    func byRelationship(_ relationship: Relationship) async throws -> [Person] {
        return try await personRepository.getByRelationship(relationship)
    }

    func search(query: String) async throws -> [Person] {
        return try await personRepository.search(query: query)
    }

    func recentlyMet(limit: Int = 5) async throws -> [Person] {
        return try await personRepository.getRecentlyMet(limit: limit)
    }
}
