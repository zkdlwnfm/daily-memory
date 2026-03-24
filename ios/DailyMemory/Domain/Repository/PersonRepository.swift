import Foundation
import Combine

/// Repository protocol for Person operations.
/// Defines the contract for data access, implemented in data layer.
protocol PersonRepository {
    // CRUD Operations
    func save(_ person: Person) async throws
    func update(_ person: Person) async throws
    func delete(id: String) async throws

    // Query - Single
    func getById(_ id: String) async throws -> Person?

    // Query - All (with different sorting)
    func getAll(sortedBy: PersonSortOrder) async throws -> [Person]

    // Query - By Relationship
    func getByRelationship(_ relationship: Relationship) async throws -> [Person]

    // Query - Search
    func search(query: String) async throws -> [Person]

    // Query - Recently Met
    func getRecentlyMet(limit: Int) async throws -> [Person]

    // Statistics
    func getCount() async throws -> Int
    func incrementMeetingCount(id: String, date: Date) async throws
}

/// Sort order for persons
enum PersonSortOrder {
    case alphabetical
    case recentMeeting
    case mostFrequent
}
