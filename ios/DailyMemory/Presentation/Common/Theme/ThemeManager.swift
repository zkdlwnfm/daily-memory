import SwiftUI

/// 앱 테마 관리
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.sage.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .sage
    }
}

/// 앱 컬러 테마
enum AppTheme: String, CaseIterable, Identifiable {
    case sage = "Ink Sage"
    case ocean = "Deep Ocean"
    case lavender = "Soft Lavender"
    case midnight = "Midnight"
    case terracotta = "Terracotta"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .sage: return Color(hex: "3D5A50")
        case .ocean: return Color(hex: "1E3A5F")
        case .lavender: return Color(hex: "6B5B95")
        case .midnight: return Color(hex: "2C3E50")
        case .terracotta: return Color(hex: "C4784D")
        }
    }

    var primaryLight: Color {
        switch self {
        case .sage: return Color(hex: "6B8F7E")
        case .ocean: return Color(hex: "4A90B8")
        case .lavender: return Color(hex: "9B8EC4")
        case .midnight: return Color(hex: "5D7B93")
        case .terracotta: return Color(hex: "D4956B")
        }
    }

    var primaryDark: Color {
        switch self {
        case .sage: return Color(hex: "2D4339")
        case .ocean: return Color(hex: "122740")
        case .lavender: return Color(hex: "4A3D6E")
        case .midnight: return Color(hex: "1A252F")
        case .terracotta: return Color(hex: "8B5633")
        }
    }

    var preview: [Color] {
        [primaryDark, primary, primaryLight]
    }
}
