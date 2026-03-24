import Foundation

/// Implementation of MemoryRepository using MemoryStore
final class MemoryRepositoryImpl: MemoryRepository {
    private let store: MemoryStore

    init(store: MemoryStore = MemoryStore()) {
        self.store = store
    }

    // CRUD Operations
    func save(_ memory: Memory) async throws {
        try store.create(memory)
    }

    func update(_ memory: Memory) async throws {
        var updatedMemory = memory
        updatedMemory.updatedAt = Date()
        try store.update(updatedMemory)
    }

    func delete(id: String) async throws {
        try store.delete(id: id)
    }

    // Query - Single
    func getById(_ id: String) async throws -> Memory? {
        return try store.read(id: id)
    }

    // Query - All
    func getAll() async throws -> [Memory] {
        return try store.fetchAll()
    }

    func getRecent(limit: Int) async throws -> [Memory] {
        return try store.fetchRecent(limit: limit)
    }

    // Query - By Date
    func getByDateRange(from: Date, to: Date) async throws -> [Memory] {
        return try store.fetchByDateRange(from: from, to: to)
    }

    func getByDate(_ date: Date) async throws -> [Memory] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return try store.fetchByDateRange(from: startOfDay, to: endOfDay)
    }

    // Query - By Category
    func getByCategory(_ category: Category) async throws -> [Memory] {
        return try store.fetchByCategory(category)
    }

    // Query - By Person
    func getByPersonId(_ personId: String) async throws -> [Memory] {
        // Filter memories that contain the personId
        let allMemories = try store.fetchAll()
        return allMemories.filter { $0.personIds.contains(personId) }
    }

    // Query - Search
    func search(query: String) async throws -> [Memory] {
        return try store.search(query: query)
    }

    // Query - Security
    func getForAI() async throws -> [Memory] {
        return try store.fetchForAI()
    }

    // Statistics
    func getCount() async throws -> Int {
        return try store.count()
    }
}
