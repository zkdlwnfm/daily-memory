import Foundation
import Combine

/// Repository protocol for Memory operations.
/// Defines the contract for data access, implemented in data layer.
protocol MemoryRepository {
    // CRUD Operations
    func save(_ memory: Memory) async throws
    func update(_ memory: Memory) async throws
    func delete(id: String) async throws

    // Query - Single
    func getById(_ id: String) async throws -> Memory?

    // Query - All
    func getAll() async throws -> [Memory]
    func getRecent(limit: Int) async throws -> [Memory]

    // Query - By Date
    func getByDateRange(from: Date, to: Date) async throws -> [Memory]
    func getByDate(_ date: Date) async throws -> [Memory]

    // Query - By Category
    func getByCategory(_ category: Category) async throws -> [Memory]

    // Query - By Person
    func getByPersonId(_ personId: String) async throws -> [Memory]

    // Query - Search
    func search(query: String) async throws -> [Memory]

    // Query - Security
    func getForAI() async throws -> [Memory]

    // Statistics
    func getCount() async throws -> Int
}
