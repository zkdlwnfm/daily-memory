import Foundation

/// Use case for fetching all open (incomplete) tasks, sorted by due date.
final class GetOpenTasksUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute() async throws -> [MemoryTask] {
        try await taskRepository.getOpen()
    }
}
