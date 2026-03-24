import Foundation

/// Use case for getting a single memory by ID.
final class GetMemoryUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository = MemoryRepositoryImpl()) {
        self.memoryRepository = memoryRepository
    }

    func execute(id: String) async throws -> Memory? {
        return try await memoryRepository.getById(id)
    }
}
