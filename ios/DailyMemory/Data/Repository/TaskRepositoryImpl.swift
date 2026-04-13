import Foundation

/// Implementation of TaskRepository using TaskStore
final class TaskRepositoryImpl: TaskRepository {
    private let store: TaskStore

    init(store: TaskStore = TaskStore()) {
        self.store = store
    }

    // CRUD Operations
    func save(_ task: MemoryTask) async throws {
        try store.create(task)
    }

    func update(_ task: MemoryTask) async throws {
        var updatedTask = task
        updatedTask.updatedAt = Date()
        try store.update(updatedTask)
    }

    func delete(id: String) async throws {
        try store.delete(id: id)
    }

    // Query - Single
    func getById(_ id: String) async throws -> MemoryTask? {
        try store.read(id: id)
    }

    // Query - All
    func getAll() async throws -> [MemoryTask] {
        try store.fetchAll()
    }

    // Query - By Status
    func getByStatus(_ status: TaskStatus) async throws -> [MemoryTask] {
        try store.fetchByStatus(status)
    }

    func getOpen() async throws -> [MemoryTask] {
        try store.fetchOpen()
    }

    func getCompleted() async throws -> [MemoryTask] {
        try store.fetchCompleted()
    }

    // Query - By Relationship
    func getByMemoryId(_ memoryId: String) async throws -> [MemoryTask] {
        try store.fetchByMemoryId(memoryId)
    }

    func getByPersonId(_ personId: String) async throws -> [MemoryTask] {
        try store.fetchByPersonId(personId)
    }

    // Query - By Date
    func getByDateRange(from: Date, to: Date) async throws -> [MemoryTask] {
        try store.fetchByDateRange(from: from, to: to)
    }

    // Statistics
    func getOpenCount() async throws -> Int {
        try store.openCount()
    }
}
