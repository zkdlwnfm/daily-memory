import Foundation

/// Use case for fetching tasks within a date range (for calendar display).
final class GetTasksByDateRangeUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute(from: Date, to: Date) async throws -> [MemoryTask] {
        try await taskRepository.getByDateRange(from: from, to: to)
    }
}
