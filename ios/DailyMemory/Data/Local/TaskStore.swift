import CoreData
import Foundation

/// Local data store for Task entities using Core Data
class TaskStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func create(_ task: MemoryTask) throws {
        let entity = TaskMO(context: context)
        entity.update(from: task)
        try context.save()
    }

    func read(id: String) throws -> MemoryTask? {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        return try context.fetch(request).first?.toDomainModel()
    }

    func update(_ task: MemoryTask) throws {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "id == %@", task.id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.update(from: task)
            try context.save()
        }
    }

    func delete(id: String) throws {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Query Operations

    func fetchAll(sortedBy keyPath: String = "createdAt", ascending: Bool = false) throws -> [MemoryTask] {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: ascending)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByStatus(_ status: TaskStatus) throws -> [MemoryTask] {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "statusRaw == %@", status.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true),
                                   NSSortDescriptor(key: "createdAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchOpen() throws -> [MemoryTask] {
        try fetchByStatus(.open)
    }

    func fetchCompleted() throws -> [MemoryTask] {
        try fetchByStatus(.completed)
    }

    func fetchByMemoryId(_ memoryId: String) throws -> [MemoryTask] {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "memoryId == %@", memoryId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByPersonId(_ personId: String) throws -> [MemoryTask] {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "personId == %@", personId)
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true),
                                   NSSortDescriptor(key: "createdAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByDateRange(from: Date, to: Date) throws -> [MemoryTask] {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate <= %@", from as NSDate, to as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func openCount() throws -> Int {
        let request = NSFetchRequest<TaskMO>(entityName: "TaskMO")
        request.predicate = NSPredicate(format: "statusRaw == %@", TaskStatus.open.rawValue)
        return try context.count(for: request)
    }
}
