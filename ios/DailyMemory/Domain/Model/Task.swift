import Foundation

/// Domain model for Task (할일/약속) — extracted from Memory by AI
struct MemoryTask: Identifiable, Codable, Equatable {
    let id: String
    let memoryId: String              // source memory (required)
    var personId: String?             // linked person (optional)

    var title: String
    var description: String?
    var dueDate: Date?

    var quadrant: EisenhowerQuadrant  // AI-suggested, v2 will add UI to change
    var status: TaskStatus

    let isAISuggested: Bool
    let aiConfidence: Float           // 0.0 - 1.0

    // Metadata
    let createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        memoryId: String,
        personId: String? = nil,
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        quadrant: EisenhowerQuadrant = .q2_importantNotUrgent,
        status: TaskStatus = .open,
        isAISuggested: Bool = true,
        aiConfidence: Float = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.memoryId = memoryId
        self.personId = personId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.quadrant = quadrant
        self.status = status
        self.isAISuggested = isAISuggested
        self.aiConfidence = aiConfidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    /// Whether this task is overdue
    var isOverdue: Bool {
        guard let dueDate else { return false }
        return dueDate < Date() && status == .open
    }

    /// Whether this task has a deadline
    var hasDueDate: Bool {
        dueDate != nil
    }
}

/// Eisenhower Matrix quadrant classification
enum EisenhowerQuadrant: String, Codable, CaseIterable {
    case q1_urgentImportant     = "Q1"  // Do — urgent and important
    case q2_importantNotUrgent  = "Q2"  // Schedule — important but not urgent
    case q3_urgentNotImportant  = "Q3"  // Delegate — urgent but not important
    case q4_neither             = "Q4"  // Eliminate — neither urgent nor important

    var displayName: String {
        switch self {
        case .q1_urgentImportant: return "Do"
        case .q2_importantNotUrgent: return "Schedule"
        case .q3_urgentNotImportant: return "Delegate"
        case .q4_neither: return "Eliminate"
        }
    }

    var icon: String {
        switch self {
        case .q1_urgentImportant: return "bolt.fill"
        case .q2_importantNotUrgent: return "calendar.badge.clock"
        case .q3_urgentNotImportant: return "arrow.right.circle"
        case .q4_neither: return "archivebox"
        }
    }
}

/// Task lifecycle status
enum TaskStatus: String, Codable, CaseIterable {
    case open        = "OPEN"
    case inProgress  = "IN_PROGRESS"
    case completed   = "COMPLETED"
    case cancelled   = "CANCELLED"

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .open: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

/// AI-extracted task from memory analysis (DTO, not persisted)
struct ExtractedTask: Codable {
    let title: String
    let description: String?
    let dueDate: String?         // ISO 8601 from backend
    let urgency: Int             // 1-5
    let importance: Int          // 1-5
    let relatedPerson: String?   // person name for matching
}
