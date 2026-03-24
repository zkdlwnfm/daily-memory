import Foundation
import Combine

/// Repository protocol for Reminder operations.
/// Defines the contract for data access, implemented in data layer.
protocol ReminderRepository {
    // CRUD Operations
    func save(_ reminder: Reminder) async throws
    func update(_ reminder: Reminder) async throws
    func delete(id: String) async throws

    // Query - Single
    func getById(_ id: String) async throws -> Reminder?

    // Query - All
    func getAll() async throws -> [Reminder]
    func getActive() async throws -> [Reminder]

    // Query - By Date
    func getByDate(_ date: Date) async throws -> [Reminder]
    func getUpcoming(from: Date, limit: Int) async throws -> [Reminder]
    func getOverdue() async throws -> [Reminder]

    // Query - By Related Entity
    func getByMemoryId(_ memoryId: String) async throws -> [Reminder]
    func getByPersonId(_ personId: String) async throws -> [Reminder]

    // Actions
    func markAsTriggered(id: String) async throws
    func setActive(id: String, isActive: Bool) async throws

    // Statistics
    func getActiveCount() async throws -> Int
}
