import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Firestore service for cloud sync of Memory, Person, Reminder data
final class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private let authService = AuthService.shared

    private init() {
        configureFirestore()
    }

    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
    }

    var userId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Collection References

    private func memoriesCollection() -> CollectionReference? {
        guard let uid = userId else { return nil }
        return db.collection("users").document(uid).collection("memories")
    }

    private func personsCollection() -> CollectionReference? {
        guard let uid = userId else { return nil }
        return db.collection("users").document(uid).collection("persons")
    }

    private func remindersCollection() -> CollectionReference? {
        guard let uid = userId else { return nil }
        return db.collection("users").document(uid).collection("reminders")
    }

    private func userDocument() -> DocumentReference? {
        guard let uid = userId else { return nil }
        return db.collection("users").document(uid)
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async throws {
        guard let docRef = userDocument() else { return }

        let data: [String: Any] = [
            "uid": profile.uid,
            "email": profile.email ?? "",
            "displayName": profile.displayName ?? "",
            "photoURL": profile.photoURL ?? "",
            "isPremium": profile.isPremium,
            "createdAt": Timestamp(date: profile.createdAt),
            "lastLoginAt": Timestamp(date: profile.lastLoginAt)
        ]

        try await docRef.setData(data, merge: true)
    }

    func getUserProfile() async throws -> UserProfile? {
        guard let docRef = userDocument() else { return nil }

        let snapshot = try await docRef.getDocument()
        guard let data = snapshot.data() else { return nil }

        return UserProfile(
            uid: data["uid"] as? String ?? "",
            email: data["email"] as? String,
            displayName: data["displayName"] as? String,
            photoURL: data["photoURL"] as? String,
            isPremium: data["isPremium"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    // MARK: - Memories CRUD

    func saveMemory(_ memory: Memory) async throws {
        guard let collection = memoriesCollection() else { return }

        let data = encodeMemory(memory)
        try await collection.document(memory.id).setData(data, merge: true)
    }

    func deleteMemory(id: String) async throws {
        guard let collection = memoriesCollection() else { return }
        try await collection.document(id).delete()
    }

    func fetchMemories(since date: Date? = nil) async throws -> [Memory] {
        guard let collection = memoriesCollection() else { return [] }

        var query: Query = collection.order(by: "updatedAt", descending: true)

        if let date = date {
            query = query.whereField("updatedAt", isGreaterThan: Timestamp(date: date))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { decodeMemory($0.data()) }
    }

    func fetchMemory(id: String) async throws -> Memory? {
        guard let collection = memoriesCollection() else { return nil }

        let snapshot = try await collection.document(id).getDocument()
        guard let data = snapshot.data() else { return nil }
        return decodeMemory(data)
    }

    // MARK: - Persons CRUD

    func savePerson(_ person: Person) async throws {
        guard let collection = personsCollection() else { return }

        let data = encodePerson(person)
        try await collection.document(person.id).setData(data, merge: true)
    }

    func deletePerson(id: String) async throws {
        guard let collection = personsCollection() else { return }
        try await collection.document(id).delete()
    }

    func fetchPersons(since date: Date? = nil) async throws -> [Person] {
        guard let collection = personsCollection() else { return [] }

        var query: Query = collection.order(by: "updatedAt", descending: true)

        if let date = date {
            query = query.whereField("updatedAt", isGreaterThan: Timestamp(date: date))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { decodePerson($0.data()) }
    }

    // MARK: - Reminders CRUD

    func saveReminder(_ reminder: Reminder) async throws {
        guard let collection = remindersCollection() else { return }

        let data = encodeReminder(reminder)
        try await collection.document(reminder.id).setData(data, merge: true)
    }

    func deleteReminder(id: String) async throws {
        guard let collection = remindersCollection() else { return }
        try await collection.document(id).delete()
    }

    func fetchReminders(since date: Date? = nil) async throws -> [Reminder] {
        guard let collection = remindersCollection() else { return [] }

        var query: Query = collection.order(by: "scheduledAt", descending: true)

        if let date = date {
            query = query.whereField("updatedAt", isGreaterThan: Timestamp(date: date))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { decodeReminder($0.data()) }
    }

    // MARK: - Real-time Listeners

    func listenToMemories(onChange: @escaping ([Memory]) -> Void) -> ListenerRegistration? {
        guard let collection = memoriesCollection() else { return nil }

        return collection
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else { return }

                let memories = snapshot.documents.compactMap { self.decodeMemory($0.data()) }
                onChange(memories)
            }
    }

    func listenToPersons(onChange: @escaping ([Person]) -> Void) -> ListenerRegistration? {
        guard let collection = personsCollection() else { return nil }

        return collection
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else { return }

                let persons = snapshot.documents.compactMap { self.decodePerson($0.data()) }
                onChange(persons)
            }
    }

    // MARK: - Batch Operations

    func batchSaveMemories(_ memories: [Memory]) async throws {
        guard memoriesCollection() != nil else { return }

        let batch = db.batch()

        for memory in memories {
            guard let collection = memoriesCollection() else { continue }
            let docRef = collection.document(memory.id)
            batch.setData(encodeMemory(memory), forDocument: docRef, merge: true)
        }

        try await batch.commit()
    }

    func batchSavePersons(_ persons: [Person]) async throws {
        guard personsCollection() != nil else { return }

        let batch = db.batch()

        for person in persons {
            guard let collection = personsCollection() else { continue }
            let docRef = collection.document(person.id)
            batch.setData(encodePerson(person), forDocument: docRef, merge: true)
        }

        try await batch.commit()
    }

    // MARK: - Encoding

    private func encodeMemory(_ memory: Memory) -> [String: Any] {
        var data: [String: Any] = [
            "id": memory.id,
            "content": memory.content,
            "extractedPersons": memory.extractedPersons,
            "extractedTags": memory.extractedTags,
            "personIds": memory.personIds,
            "category": memory.category.rawValue,
            "importance": memory.importance,
            "isLocked": memory.isLocked,
            "excludeFromAI": memory.excludeFromAI,
            "recordedAt": Timestamp(date: memory.recordedAt),
            "createdAt": Timestamp(date: memory.createdAt),
            "updatedAt": Timestamp(date: memory.updatedAt),
            "syncStatus": SyncStatus.synced.rawValue
        ]

        if let location = memory.extractedLocation {
            data["extractedLocation"] = location
        }
        if let date = memory.extractedDate {
            data["extractedDate"] = Timestamp(date: date)
        }
        if let amount = memory.extractedAmount {
            data["extractedAmount"] = amount
        }
        if let lat = memory.recordedLatitude {
            data["recordedLatitude"] = lat
        }
        if let lng = memory.recordedLongitude {
            data["recordedLongitude"] = lng
        }

        // Encode photos (without embedding/local paths)
        let photosData = memory.photos.map { photo -> [String: Any] in
            var photoMap: [String: Any] = [
                "id": photo.id,
                "url": photo.url,
                "createdAt": Timestamp(date: photo.createdAt)
            ]
            if let thumbnail = photo.thumbnailUrl {
                photoMap["thumbnailUrl"] = thumbnail
            }
            if let analysis = photo.aiAnalysis {
                photoMap["aiAnalysis"] = analysis
            }
            return photoMap
        }
        data["photos"] = photosData

        return data
    }

    private func encodePerson(_ person: Person) -> [String: Any] {
        var data: [String: Any] = [
            "id": person.id,
            "name": person.name,
            "relationship": person.relationship.rawValue,
            "meetingCount": person.meetingCount,
            "createdAt": Timestamp(date: person.createdAt),
            "updatedAt": Timestamp(date: person.updatedAt),
            "syncStatus": SyncStatus.synced.rawValue
        ]

        if let nickname = person.nickname { data["nickname"] = nickname }
        if let phone = person.phone { data["phone"] = phone }
        if let email = person.email { data["email"] = email }
        if let summary = person.summary { data["summary"] = summary }
        if let lastMeetingDate = person.lastMeetingDate { data["lastMeetingDate"] = Timestamp(date: lastMeetingDate) }
        if let profileImageUrl = person.profileImageUrl { data["profileImageUrl"] = profileImageUrl }
        if let memo = person.memo { data["memo"] = memo }

        return data
    }

    private func encodeReminder(_ reminder: Reminder) -> [String: Any] {
        var data: [String: Any] = [
            "id": reminder.id,
            "title": reminder.title,
            "body": reminder.body,
            "scheduledAt": Timestamp(date: reminder.scheduledAt),
            "repeatType": reminder.repeatType.rawValue,
            "isActive": reminder.isActive,
            "isAutoGenerated": reminder.isAutoGenerated,
            "createdAt": Timestamp(date: reminder.createdAt),
            "updatedAt": Timestamp(date: reminder.updatedAt),
            "syncStatus": SyncStatus.synced.rawValue
        ]

        if let memoryId = reminder.memoryId { data["memoryId"] = memoryId }
        if let personId = reminder.personId { data["personId"] = personId }
        if let triggeredAt = reminder.triggeredAt { data["triggeredAt"] = Timestamp(date: triggeredAt) }

        // Location fields
        if let lat = reminder.latitude { data["latitude"] = lat }
        if let lng = reminder.longitude { data["longitude"] = lng }
        if let radius = reminder.radius { data["radius"] = radius }
        if let triggerType = reminder.locationTriggerType { data["locationTriggerType"] = triggerType.rawValue }
        if let locationName = reminder.locationName { data["locationName"] = locationName }

        return data
    }

    // MARK: - Decoding

    private func decodeMemory(_ data: [String: Any]) -> Memory? {
        guard let id = data["id"] as? String,
              let content = data["content"] as? String else { return nil }

        let photosData = data["photos"] as? [[String: Any]] ?? []
        let photos = photosData.compactMap { photoData -> Photo? in
            guard let id = photoData["id"] as? String,
                  let url = photoData["url"] as? String else { return nil }
            return Photo(
                id: id,
                url: url,
                thumbnailUrl: photoData["thumbnailUrl"] as? String,
                aiAnalysis: photoData["aiAnalysis"] as? String,
                createdAt: (photoData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }

        let categoryRaw = data["category"] as? String ?? Category.general.rawValue

        return Memory(
            id: id,
            content: content,
            photos: photos,
            extractedPersons: data["extractedPersons"] as? [String] ?? [],
            extractedLocation: data["extractedLocation"] as? String,
            extractedDate: (data["extractedDate"] as? Timestamp)?.dateValue(),
            extractedAmount: data["extractedAmount"] as? Double,
            extractedTags: data["extractedTags"] as? [String] ?? [],
            personIds: data["personIds"] as? [String] ?? [],
            category: Category(rawValue: categoryRaw) ?? .general,
            importance: data["importance"] as? Int ?? 3,
            isLocked: data["isLocked"] as? Bool ?? false,
            excludeFromAI: data["excludeFromAI"] as? Bool ?? false,
            recordedAt: (data["recordedAt"] as? Timestamp)?.dateValue() ?? Date(),
            recordedLatitude: data["recordedLatitude"] as? Double,
            recordedLongitude: data["recordedLongitude"] as? Double,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            syncStatus: .synced
        )
    }

    private func decodePerson(_ data: [String: Any]) -> Person? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String else { return nil }

        let relationshipRaw = data["relationship"] as? String ?? Relationship.other.rawValue

        return Person(
            id: id,
            name: name,
            nickname: data["nickname"] as? String,
            relationship: Relationship(rawValue: relationshipRaw) ?? .other,
            phone: data["phone"] as? String,
            email: data["email"] as? String,
            summary: data["summary"] as? String,
            meetingCount: data["meetingCount"] as? Int ?? 0,
            lastMeetingDate: (data["lastMeetingDate"] as? Timestamp)?.dateValue(),
            profileImageUrl: data["profileImageUrl"] as? String,
            memo: data["memo"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            syncStatus: .synced
        )
    }

    private func decodeReminder(_ data: [String: Any]) -> Reminder? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String else { return nil }

        let repeatRaw = data["repeatType"] as? String ?? RepeatType.none.rawValue
        let triggerTypeRaw = data["locationTriggerType"] as? String

        return Reminder(
            id: id,
            memoryId: data["memoryId"] as? String,
            personId: data["personId"] as? String,
            title: title,
            body: data["body"] as? String ?? "",
            scheduledAt: (data["scheduledAt"] as? Timestamp)?.dateValue() ?? Date(),
            repeatType: RepeatType(rawValue: repeatRaw) ?? .none,
            isActive: data["isActive"] as? Bool ?? true,
            isAutoGenerated: data["isAutoGenerated"] as? Bool ?? false,
            triggeredAt: (data["triggeredAt"] as? Timestamp)?.dateValue(),
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            radius: data["radius"] as? Double,
            locationTriggerType: triggerTypeRaw.flatMap { LocationTriggerType(rawValue: $0) },
            locationName: data["locationName"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
