import Foundation

/// Implementation of ReminderRepository using ReminderStore
final class ReminderRepositoryImpl: ReminderRepository {
    private let store: ReminderStore

    init(store: ReminderStore = ReminderStore()) {
        self.store = store
    }

    // CRUD Operations
    func save(_ reminder: Reminder) async throws {
        try store.create(reminder)
    }

    func update(_ reminder: Reminder) async throws {
        var updatedReminder = reminder
        updatedReminder.updatedAt = Date()
        try store.update(updatedReminder)
    }

    func delete(id: String) async throws {
        try store.delete(id: id)
    }

    // Query - Single
    func getById(_ id: String) async throws -> Reminder? {
        return try store.read(id: id)
    }

    // Query - All
    func getAll() async throws -> [Reminder] {
        return try store.fetchAll()
    }

    func getActive() async throws -> [Reminder] {
        return try store.fetchActive()
    }

    // Query - By Date
    func getByDate(_ date: Date) async throws -> [Reminder] {
        return try store.fetchForDate(date)
    }

    func getUpcoming(from: Date, limit: Int) async throws -> [Reminder] {
        return try store.fetchUpcoming(from: from, limit: limit)
    }

    func getOverdue() async throws -> [Reminder] {
        return try store.fetchOverdue()
    }

    // Query - By Related Entity
    func getByMemoryId(_ memoryId: String) async throws -> [Reminder] {
        return try store.fetchByMemory(memoryId: memoryId)
    }

    func getByPersonId(_ personId: String) async throws -> [Reminder] {
        return try store.fetchByPerson(personId: personId)
    }

    // Actions
    func markAsTriggered(id: String) async throws {
        try store.markAsTriggered(id: id)
    }

    func setActive(id: String, isActive: Bool) async throws {
        try store.setActive(id: id, isActive: isActive)
    }

    // Statistics
    func getActiveCount() async throws -> Int {
        return try store.activeCount()
    }
}
