import Foundation

/// Use case for saving a new task extracted from a memory.
final class SaveTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: MemoryTask) async throws {
        try await taskRepository.save(task)
    }
}
