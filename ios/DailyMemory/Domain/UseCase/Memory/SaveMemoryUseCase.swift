import Foundation

/// Use case for saving a new memory.
/// Handles the business logic of creating a memory and updating related persons.
final class SaveMemoryUseCase {
    private let memoryRepository: MemoryRepository
    private let personRepository: PersonRepository

    init(
        memoryRepository: MemoryRepository = MemoryRepositoryImpl(),
        personRepository: PersonRepository = PersonRepositoryImpl()
    ) {
        self.memoryRepository = memoryRepository
        self.personRepository = personRepository
    }

    func execute(_ memory: Memory) async throws -> Memory {
        // Save the memory
        try await memoryRepository.save(memory)

        // Update meeting count for related persons
        for personId in memory.personIds {
            try await personRepository.incrementMeetingCount(id: personId, date: memory.recordedAt)
        }

        return memory
    }
}
