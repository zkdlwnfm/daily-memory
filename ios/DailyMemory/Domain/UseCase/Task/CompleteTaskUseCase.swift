import Foundation

/// Use case for marking a task as completed.
final class CompleteTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute(taskId: String) async throws {
        guard var task = try await taskRepository.getById(taskId) else { return }
        task.status = .completed
        task.updatedAt = Date()
        try await taskRepository.update(task)
    }
}
