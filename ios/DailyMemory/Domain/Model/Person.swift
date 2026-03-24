import Foundation

/// Domain model for Person (인물)
struct Person: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var nickname: String?
    var relationship: Relationship

    // Contact Info (optional)
    var phone: String?
    var email: String?

    // AI Generated Summary
    var summary: String?

    // Statistics (auto-calculated)
    var meetingCount: Int
    var lastMeetingDate: Date?

    // Profile
    var profileImageUrl: String?
    var memo: String?

    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        name: String,
        nickname: String? = nil,
        relationship: Relationship = .other,
        phone: String? = nil,
        email: String? = nil,
        summary: String? = nil,
        meetingCount: Int = 0,
        lastMeetingDate: Date? = nil,
        profileImageUrl: String? = nil,
        memo: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.relationship = relationship
        self.phone = phone
        self.email = email
        self.summary = summary
        self.meetingCount = meetingCount
        self.lastMeetingDate = lastMeetingDate
        self.profileImageUrl = profileImageUrl
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    /// Get initials for avatar
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

/// Relationship type
enum Relationship: String, Codable, CaseIterable {
    case family = "FAMILY"             // 가족
    case friend = "FRIEND"             // 친구
    case colleague = "COLLEAGUE"       // 동료
    case business = "BUSINESS"         // 비즈니스
    case acquaintance = "ACQUAINTANCE" // 지인
    case other = "OTHER"               // 기타

    var displayName: String {
        switch self {
        case .family: return "Family"
        case .friend: return "Friend"
        case .colleague: return "Colleague"
        case .business: return "Business"
        case .acquaintance: return "Acquaintance"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .family: return "heart.fill"
        case .friend: return "person.2.fill"
        case .colleague: return "briefcase.fill"
        case .business: return "building.2.fill"
        case .acquaintance: return "person.fill"
        case .other: return "person.fill.questionmark"
        }
    }
}
