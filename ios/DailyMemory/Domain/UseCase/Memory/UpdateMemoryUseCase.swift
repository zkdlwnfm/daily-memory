import Foundation

/// Use case for updating an existing memory.
final class UpdateMemoryUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository = MemoryRepositoryImpl()) {
        self.memoryRepository = memoryRepository
    }

    func execute(_ memory: Memory) async throws -> Memory {
        try await memoryRepository.update(memory)
        await SyncManager.shared.enqueueMemoryChange(id: memory.id, type: .update)
        return memory
    }
}
