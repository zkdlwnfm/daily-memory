import Foundation

/// Repository protocol for Task operations.
/// Defines the contract for data access, implemented in data layer.
protocol TaskRepository {
    // CRUD Operations
    func save(_ task: MemoryTask) async throws
    func update(_ task: MemoryTask) async throws
    func delete(id: String) async throws

    // Query - Single
    func getById(_ id: String) async throws -> MemoryTask?

    // Query - All
    func getAll() async throws -> [MemoryTask]

    // Query - By Status
    func getByStatus(_ status: TaskStatus) async throws -> [MemoryTask]
    func getOpen() async throws -> [MemoryTask]
    func getCompleted() async throws -> [MemoryTask]

    // Query - By Relationship
    func getByMemoryId(_ memoryId: String) async throws -> [MemoryTask]
    func getByPersonId(_ personId: String) async throws -> [MemoryTask]

    // Query - By Date
    func getByDateRange(from: Date, to: Date) async throws -> [MemoryTask]

    // Statistics
    func getOpenCount() async throws -> Int
}
