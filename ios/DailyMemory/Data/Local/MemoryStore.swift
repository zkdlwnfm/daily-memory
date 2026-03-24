import CoreData
import Foundation
import Combine

/// Local data store for Memory entities using Core Data
class MemoryStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func create(_ memory: Memory) throws {
        let entity = MemoryMO(context: context)
        entity.update(from: memory)
        try context.save()
    }

    func read(id: String) throws -> Memory? {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        return try context.fetch(request).first?.toDomainModel()
    }

    func update(_ memory: Memory) throws {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "id == %@", memory.id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.update(from: memory)
            try context.save()
        }
    }

    func delete(id: String) throws {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Query Operations

    func fetchAll(sortedBy keyPath: String = "recordedAt", ascending: Bool = false) throws -> [Memory] {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: ascending)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchRecent(limit: Int) throws -> [Memory] {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        request.fetchLimit = limit
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByDateRange(from: Date, to: Date) throws -> [Memory] {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "recordedAt >= %@ AND recordedAt <= %@", from as NSDate, to as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByCategory(_ category: Category) throws -> [Memory] {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "categoryRaw == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func search(query: String) throws -> [Memory] {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchForAI() throws -> [Memory] {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        request.predicate = NSPredicate(format: "excludeFromAI == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func count() throws -> Int {
        let request = NSFetchRequest<MemoryMO>(entityName: "MemoryMO")
        return try context.count(for: request)
    }
}
