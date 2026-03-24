import Foundation

/// Use case for getting recent memories.
final class GetRecentMemoriesUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository = MemoryRepositoryImpl()) {
        self.memoryRepository = memoryRepository
    }

    func execute(limit: Int = 10) async throws -> [Memory] {
        return try await memoryRepository.getRecent(limit: limit)
    }
}
