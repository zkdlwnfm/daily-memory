import Foundation

/// Use case for deleting a task.
final class DeleteTaskUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute(id: String) async throws {
        try await taskRepository.delete(id: id)
    }
}
