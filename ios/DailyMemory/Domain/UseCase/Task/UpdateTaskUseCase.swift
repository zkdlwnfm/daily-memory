import Foundation

/// Use case for updating an existing task.
final class UpdateTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute(_ task: MemoryTask) async throws {
        var updated = task
        updated.updatedAt = Date()
        try await taskRepository.update(updated)
    }
}
