import Foundation

/// Implementation of PersonRepository using PersonStore
final class PersonRepositoryImpl: PersonRepository {
    private let store: PersonStore

    init(store: PersonStore = PersonStore()) {
        self.store = store
    }

    // CRUD Operations
    func save(_ person: Person) async throws {
        try store.create(person)
    }

    func update(_ person: Person) async throws {
        var updatedPerson = person
        updatedPerson.updatedAt = Date()
        try store.update(updatedPerson)
    }

    func delete(id: String) async throws {
        try store.delete(id: id)
    }

    // Query - Single
    func getById(_ id: String) async throws -> Person? {
        return try store.read(id: id)
    }

    // Query - All (with different sorting)
    func getAll(sortedBy: PersonSortOrder) async throws -> [Person] {
        switch sortedBy {
        case .alphabetical:
            return try store.fetchAll(sortedBy: "name", ascending: true)
        case .recentMeeting:
            return try store.fetchAll(sortedBy: "lastMeetingDate", ascending: false)
        case .mostFrequent:
            return try store.fetchAll(sortedBy: "meetingCount", ascending: false)
        }
    }

    // Query - By Relationship
    func getByRelationship(_ relationship: Relationship) async throws -> [Person] {
        return try store.fetchByRelationship(relationship)
    }

    // Query - Search
    func search(query: String) async throws -> [Person] {
        return try store.search(query: query)
    }

    // Query - Recently Met
    func getRecentlyMet(limit: Int) async throws -> [Person] {
        return try store.fetchRecentlyMet(limit: limit)
    }

    // Statistics
    func getCount() async throws -> Int {
        return try store.count()
    }

    func incrementMeetingCount(id: String, date: Date) async throws {
        try store.incrementMeetingCount(id: id, date: date)
    }
}
