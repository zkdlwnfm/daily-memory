import SwiftUI

extension Color {
    // MARK: - Primary Colors (Indigo)
    static let dmPrimary = Color(hex: "6366F1")
    static let dmPrimaryDark = Color(hex: "4F46E5")
    static let dmPrimaryLight = Color(hex: "818CF8")

    // MARK: - Secondary Colors (Teal)
    static let dmSecondary = Color(hex: "14B8A6")
    static let dmSecondaryDark = Color(hex: "0D9488")
    static let dmSecondaryLight = Color(hex: "2DD4BF")

    // MARK: - Accent Colors
    static let dmAccent = Color(hex: "F59E0B")
    static let dmAccentLight = Color(hex: "FBBF24")

    // MARK: - Background Colors
    static let dmBackgroundLight = Color(hex: "F8FAFC")
    static let dmSurfaceLight = Color(hex: "FFFFFF")
    static let dmBackgroundDark = Color(hex: "0F172A")
    static let dmSurfaceDark = Color(hex: "1E293B")

    // MARK: - Text Colors
    static let dmTextPrimary = Color(hex: "1E293B")
    static let dmTextSecondary = Color(hex: "64748B")
    static let dmTextTertiary = Color(hex: "94A3B8")

    // MARK: - Status Colors
    static let dmSuccess = Color(hex: "22C55E")
    static let dmWarning = Color(hex: "F59E0B")
    static let dmError = Color(hex: "EF4444")
    static let dmInfo = Color(hex: "3B82F6")

    // MARK: - Category Colors
    static let dmCategoryEvent = Color(hex: "6366F1")
    static let dmCategoryPromise = Color(hex: "8B5CF6")
    static let dmCategoryMeeting = Color(hex: "14B8A6")
    static let dmCategoryFinancial = Color(hex: "F59E0B")
    static let dmCategoryGeneral = Color(hex: "64748B")

    // MARK: - Relationship Colors
    static let dmRelationshipFamily = Color(hex: "EC4899")
    static let dmRelationshipFriend = Color(hex: "3B82F6")
    static let dmRelationshipColleague = Color(hex: "14B8A6")
    static let dmRelationshipBusiness = Color(hex: "6366F1")
    static let dmRelationshipAcquaintance = Color(hex: "64748B")
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
