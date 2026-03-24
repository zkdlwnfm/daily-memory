import Foundation

/// Use case for searching memories with various filters.
final class SearchMemoriesUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository = MemoryRepositoryImpl()) {
        self.memoryRepository = memoryRepository
    }

    // Search by content
    func byContent(query: String) async throws -> [Memory] {
        return try await memoryRepository.search(query: query)
    }

    // Search by category
    func byCategory(_ category: Category) async throws -> [Memory] {
        return try await memoryRepository.getByCategory(category)
    }

    // Search by date range
    func byDateRange(from: Date, to: Date) async throws -> [Memory] {
        return try await memoryRepository.getByDateRange(from: from, to: to)
    }

    // Search by specific date
    func byDate(_ date: Date) async throws -> [Memory] {
        return try await memoryRepository.getByDate(date)
    }

    // Search by person
    func byPerson(personId: String) async throws -> [Memory] {
        return try await memoryRepository.getByPersonId(personId)
    }
}
