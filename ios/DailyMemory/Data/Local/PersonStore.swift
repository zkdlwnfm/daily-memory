import CoreData
import Foundation

/// Local data store for Person entities using Core Data
class PersonStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func create(_ person: Person) throws {
        let entity = PersonMO(context: context)
        entity.update(from: person)
        try context.save()
    }

    func read(id: String) throws -> Person? {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        return try context.fetch(request).first?.toDomainModel()
    }

    func update(_ person: Person) throws {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "id == %@", person.id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.update(from: person)
            try context.save()
        }
    }

    func delete(id: String) throws {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Query Operations

    func fetchAll(sortedBy keyPath: String = "name", ascending: Bool = true) throws -> [Person] {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: ascending)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByRelationship(_ relationship: Relationship) throws -> [Person] {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "relationshipRaw == %@", relationship.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchRecentlyMet(limit: Int) throws -> [Person] {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "lastMeetingDate != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "lastMeetingDate", ascending: false)]
        request.fetchLimit = limit
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func search(query: String) throws -> [Person] {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR nickname CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func incrementMeetingCount(id: String, date: Date) throws {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.meetingCount += 1
            entity.lastMeetingDate = date
            entity.updatedAt = Date()
            try context.save()
        }
    }

    func count() throws -> Int {
        let request = NSFetchRequest<PersonMO>(entityName: "PersonMO")
        return try context.count(for: request)
    }
}
