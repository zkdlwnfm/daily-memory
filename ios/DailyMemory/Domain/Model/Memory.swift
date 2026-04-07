import Foundation

/// Domain model for Memory (기록)
struct Memory: Identifiable, Codable, Equatable {
    let id: String
    var content: String

    // Photos
    var photos: [Photo]

    // AI Extracted Data
    var extractedPersons: [String]
    var extractedLocation: String?
    var extractedDate: Date?
    var extractedAmount: Double?
    var extractedTags: [String]

    // User Confirmed Data
    var personIds: [String]
    var category: Category
    var importance: Int // 1-5

    // Security
    var isLocked: Bool
    var excludeFromAI: Bool

    // Mood (AI extracted)
    var mood: String?        // happy, sad, excited, anxious, grateful, angry, calm, nostalgic, neutral
    var moodScore: Int?      // 1-10

    // Embedding (for vector search)
    var embedding: [Float]?

    // Metadata
    var recordedAt: Date
    var recordedLatitude: Double?
    var recordedLongitude: Double?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        content: String,
        photos: [Photo] = [],
        extractedPersons: [String] = [],
        extractedLocation: String? = nil,
        extractedDate: Date? = nil,
        extractedAmount: Double? = nil,
        extractedTags: [String] = [],
        personIds: [String] = [],
        category: Category = .general,
        importance: Int = 3,
        isLocked: Bool = false,
        excludeFromAI: Bool = false,
        mood: String? = nil,
        moodScore: Int? = nil,
        embedding: [Float]? = nil,
        recordedAt: Date = Date(),
        recordedLatitude: Double? = nil,
        recordedLongitude: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.content = content
        self.photos = photos
        self.extractedPersons = extractedPersons
        self.extractedLocation = extractedLocation
        self.extractedDate = extractedDate
        self.extractedAmount = extractedAmount
        self.extractedTags = extractedTags
        self.personIds = personIds
        self.category = category
        self.importance = importance
        self.isLocked = isLocked
        self.excludeFromAI = excludeFromAI
        self.mood = mood
        self.moodScore = moodScore
        self.embedding = embedding
        self.recordedAt = recordedAt
        self.recordedLatitude = recordedLatitude
        self.recordedLongitude = recordedLongitude
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}

/// Photo attachment
struct Photo: Identifiable, Codable, Equatable {
    let id: String
    var url: String
    var thumbnailUrl: String?
    var aiAnalysis: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        url: String,
        thumbnailUrl: String? = nil,
        aiAnalysis: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.aiAnalysis = aiAnalysis
        self.createdAt = createdAt
    }
}

/// Memory category
enum Category: String, Codable, CaseIterable {
    case event = "EVENT"           // 이벤트, 기념일
    case promise = "PROMISE"       // 약속, 할 일
    case meeting = "MEETING"       // 미팅, 만남
    case financial = "FINANCIAL"   // 금전 관계
    case general = "GENERAL"       // 일반 기록

    var displayName: String {
        switch self {
        case .event: return "Event"
        case .promise: return "Promise"
        case .meeting: return "Meeting"
        case .financial: return "Financial"
        case .general: return "General"
        }
    }

    var icon: String {
        switch self {
        case .event: return "calendar"
        case .promise: return "checkmark.circle"
        case .meeting: return "person.2"
        case .financial: return "dollarsign.circle"
        case .general: return "note.text"
        }
    }
}

/// Sync status for offline-first architecture
enum SyncStatus: String, Codable {
    case synced = "SYNCED"         // Synced with cloud
    case pending = "PENDING"       // Waiting to be synced
    case conflict = "CONFLICT"     // Sync conflict detected
    case localOnly = "LOCAL_ONLY"  // Local only (privacy mode)
}
