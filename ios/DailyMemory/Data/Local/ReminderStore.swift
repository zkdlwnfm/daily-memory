import CoreData
import Foundation

/// Local data store for Reminder entities using Core Data
class ReminderStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func create(_ reminder: Reminder) throws {
        let entity = ReminderMO(context: context)
        entity.update(from: reminder)
        try context.save()
    }

    func read(id: String) throws -> Reminder? {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        return try context.fetch(request).first?.toDomainModel()
    }

    func update(_ reminder: Reminder) throws {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "id == %@", reminder.id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.update(from: reminder)
            try context.save()
        }
    }

    func delete(id: String) throws {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Query Operations

    func fetchAll() throws -> [Reminder] {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchActive() throws -> [Reminder] {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchForDate(_ date: Date) throws -> [Reminder] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(
            format: "scheduledAt >= %@ AND scheduledAt < %@ AND isActive == YES",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchUpcoming(from: Date, limit: Int) throws -> [Reminder] {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "scheduledAt >= %@ AND isActive == YES", from as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        request.fetchLimit = limit
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchOverdue() throws -> [Reminder] {
        let now = Date()
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "scheduledAt < %@ AND triggeredAt == nil AND isActive == YES", now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByMemory(memoryId: String) throws -> [Reminder] {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "memoryId == %@", memoryId)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func fetchByPerson(personId: String) throws -> [Reminder] {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "personId == %@", personId)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomainModel() }
    }

    func markAsTriggered(id: String) throws {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.triggeredAt = Date()
            entity.updatedAt = Date()
            try context.save()
        }
    }

    func setActive(id: String, isActive: Bool) throws {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let entity = try context.fetch(request).first {
            entity.isActive = isActive
            entity.updatedAt = Date()
            try context.save()
        }
    }

    func activeCount() throws -> Int {
        let request = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        request.predicate = NSPredicate(format: "isActive == YES")
        return try context.count(for: request)
    }
}
