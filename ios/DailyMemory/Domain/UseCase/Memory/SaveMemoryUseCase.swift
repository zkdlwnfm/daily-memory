import Foundation

/// Use case for saving a new memory.
/// Handles the business logic of creating a memory and updating related persons.
final class SaveMemoryUseCase {
    private let memoryRepository: MemoryRepository
    private let personRepository: PersonRepository
    private let semanticSearchUseCase: SemanticSearchUseCase?

    init(
        memoryRepository: MemoryRepository = MemoryRepositoryImpl(),
        personRepository: PersonRepository = PersonRepositoryImpl(),
        semanticSearchUseCase: SemanticSearchUseCase? = nil
    ) {
        self.memoryRepository = memoryRepository
        self.personRepository = personRepository
        self.semanticSearchUseCase = semanticSearchUseCase
    }

    func execute(_ memory: Memory) async throws -> Memory {
        // Save the memory
        try await memoryRepository.save(memory)

        // Update meeting count for related persons
        for personId in memory.personIds {
            try await personRepository.incrementMeetingCount(id: personId, date: memory.recordedAt)
        }

        // Index for semantic search (non-blocking)
        if let semanticSearch = semanticSearchUseCase {
            Task {
                await semanticSearch.indexMemory(memory)
            }
        }

        // Trigger cloud sync
        await SyncManager.shared.enqueueMemoryChange(id: memory.id, type: .create)

        return memory
    }
}
