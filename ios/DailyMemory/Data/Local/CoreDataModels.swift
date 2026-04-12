import CoreData
import Foundation

// MARK: - MemoryMO (Managed Object)
@objc(MemoryMO)
public class MemoryMO: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var content: String
    @NSManaged public var photosData: Data?
    @NSManaged public var extractedPersonsData: Data?
    @NSManaged public var extractedLocation: String?
    @NSManaged public var extractedDate: Date?
    @NSManaged public var extractedAmount: NSNumber?
    @NSManaged public var extractedTagsData: Data?
    @NSManaged public var personIdsData: Data?
    @NSManaged public var categoryRaw: String
    @NSManaged public var importance: Int16
    @NSManaged public var isLocked: Bool
    @NSManaged public var excludeFromAI: Bool
    @NSManaged public var embeddingData: Data?
    @NSManaged public var recordedAt: Date
    @NSManaged public var recordedLatitude: NSNumber?
    @NSManaged public var recordedLongitude: NSNumber?
    @NSManaged public var mood: String?
    @NSManaged public var moodScore: NSNumber?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatusRaw: String
}

extension MemoryMO {
    func toDomainModel() -> Memory {
        let decoder = JSONDecoder()

        let photos: [Photo] = (try? decoder.decode([Photo].self, from: photosData ?? Data())) ?? []
        let extractedPersons: [String] = (try? decoder.decode([String].self, from: extractedPersonsData ?? Data())) ?? []
        let extractedTags: [String] = (try? decoder.decode([String].self, from: extractedTagsData ?? Data())) ?? []
        let personIds: [String] = (try? decoder.decode([String].self, from: personIdsData ?? Data())) ?? []
        let embedding: [Float]? = embeddingData.flatMap { try? decoder.decode([Float].self, from: $0) }

        return Memory(
            id: id,
            content: content,
            photos: photos,
            extractedPersons: extractedPersons,
            extractedLocation: extractedLocation,
            extractedDate: extractedDate,
            extractedAmount: extractedAmount?.doubleValue,
            extractedTags: extractedTags,
            personIds: personIds,
            category: Category(rawValue: categoryRaw) ?? .general,
            importance: Int(importance),
            isLocked: isLocked,
            excludeFromAI: excludeFromAI,
            mood: mood,
            moodScore: moodScore?.intValue,
            embedding: embedding,
            recordedAt: recordedAt,
            recordedLatitude: recordedLatitude?.doubleValue,
            recordedLongitude: recordedLongitude?.doubleValue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .pending
        )
    }

    func update(from memory: Memory) {
        let encoder = JSONEncoder()

        id = memory.id
        content = memory.content
        photosData = try? encoder.encode(memory.photos)
        extractedPersonsData = try? encoder.encode(memory.extractedPersons)
        extractedLocation = memory.extractedLocation
        extractedDate = memory.extractedDate
        extractedAmount = memory.extractedAmount.map { NSNumber(value: $0) }
        extractedTagsData = try? encoder.encode(memory.extractedTags)
        personIdsData = try? encoder.encode(memory.personIds)
        categoryRaw = memory.category.rawValue
        importance = Int16(memory.importance)
        isLocked = memory.isLocked
        excludeFromAI = memory.excludeFromAI
        embeddingData = memory.embedding.flatMap { try? encoder.encode($0) }
        mood = memory.mood
        moodScore = memory.moodScore.map { NSNumber(value: $0) }
        recordedAt = memory.recordedAt
        recordedLatitude = memory.recordedLatitude.map { NSNumber(value: $0) }
        recordedLongitude = memory.recordedLongitude.map { NSNumber(value: $0) }
        createdAt = memory.createdAt
        updatedAt = memory.updatedAt
        syncStatusRaw = memory.syncStatus.rawValue
    }
}

// MARK: - PersonMO (Managed Object)
@objc(PersonMO)
public class PersonMO: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var nickname: String?
    @NSManaged public var relationshipRaw: String
    @NSManaged public var phone: String?
    @NSManaged public var email: String?
    @NSManaged public var summary: String?
    @NSManaged public var meetingCount: Int32
    @NSManaged public var lastMeetingDate: Date?
    @NSManaged public var profileImageUrl: String?
    @NSManaged public var memo: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatusRaw: String
}

extension PersonMO {
    func toDomainModel() -> Person {
        Person(
            id: id,
            name: name,
            nickname: nickname,
            relationship: Relationship(rawValue: relationshipRaw) ?? .other,
            phone: phone,
            email: email,
            summary: summary,
            meetingCount: Int(meetingCount),
            lastMeetingDate: lastMeetingDate,
            profileImageUrl: profileImageUrl,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .pending
        )
    }

    func update(from person: Person) {
        id = person.id
        name = person.name
        nickname = person.nickname
        relationshipRaw = person.relationship.rawValue
        phone = person.phone
        email = person.email
        summary = person.summary
        meetingCount = Int32(person.meetingCount)
        lastMeetingDate = person.lastMeetingDate
        profileImageUrl = person.profileImageUrl
        memo = person.memo
        createdAt = person.createdAt
        updatedAt = person.updatedAt
        syncStatusRaw = person.syncStatus.rawValue
    }
}

// MARK: - ReminderMO (Managed Object)
@objc(ReminderMO)
public class ReminderMO: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var memoryId: String?
    @NSManaged public var personId: String?
    @NSManaged public var title: String
    @NSManaged public var body: String
    @NSManaged public var scheduledAt: Date
    @NSManaged public var repeatTypeRaw: String
    @NSManaged public var isActive: Bool
    @NSManaged public var isAutoGenerated: Bool
    @NSManaged public var triggeredAt: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatusRaw: String
}

extension ReminderMO {
    func toDomainModel() -> Reminder {
        Reminder(
            id: id,
            memoryId: memoryId,
            personId: personId,
            title: title,
            body: body,
            scheduledAt: scheduledAt,
            repeatType: RepeatType(rawValue: repeatTypeRaw) ?? .none,
            isActive: isActive,
            isAutoGenerated: isAutoGenerated,
            triggeredAt: triggeredAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .pending
        )
    }

    func update(from reminder: Reminder) {
        id = reminder.id
        memoryId = reminder.memoryId
        personId = reminder.personId
        title = reminder.title
        body = reminder.body
        scheduledAt = reminder.scheduledAt
        repeatTypeRaw = reminder.repeatType.rawValue
        isActive = reminder.isActive
        isAutoGenerated = reminder.isAutoGenerated
        triggeredAt = reminder.triggeredAt
        createdAt = reminder.createdAt
        updatedAt = reminder.updatedAt
        syncStatusRaw = reminder.syncStatus.rawValue
    }
}
