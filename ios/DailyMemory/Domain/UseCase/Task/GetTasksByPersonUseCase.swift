import Foundation

/// Use case for fetching tasks linked to a specific person.
final class GetTasksByPersonUseCase {
    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepositoryImpl()) {
        self.taskRepository = taskRepository
    }

    func execute(personId: String) async throws -> [MemoryTask] {
        try await taskRepository.getByPersonId(personId)
    }
}
