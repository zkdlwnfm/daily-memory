import Foundation
import Combine

/// User preferences manager using UserDefaults
final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let userName = "user_name"
        static let isOnboarded = "is_onboarded"
        static let themeMode = "theme_mode"
        static let notificationsEnabled = "notifications_enabled"
        static let biometricEnabled = "biometric_enabled"
        static let autoSaveEnabled = "auto_save_enabled"
        static let lastSyncTime = "last_sync_time"
    }

    // MARK: - Published Properties

    @Published var userName: String {
        didSet { defaults.set(userName, forKey: Keys.userName) }
    }

    @Published var isOnboarded: Bool {
        didSet { defaults.set(isOnboarded, forKey: Keys.isOnboarded) }
    }

    @Published var themeMode: ThemeMode {
        didSet { defaults.set(themeMode.rawValue, forKey: Keys.themeMode) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var biometricEnabled: Bool {
        didSet { defaults.set(biometricEnabled, forKey: Keys.biometricEnabled) }
    }

    @Published var autoSaveEnabled: Bool {
        didSet { defaults.set(autoSaveEnabled, forKey: Keys.autoSaveEnabled) }
    }

    @Published var lastSyncTime: Date? {
        didSet { defaults.set(lastSyncTime, forKey: Keys.lastSyncTime) }
    }

    // MARK: - Theme Mode Enum

    enum ThemeMode: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Load saved values or use defaults
        self.userName = defaults.string(forKey: Keys.userName) ?? "User"
        self.isOnboarded = defaults.bool(forKey: Keys.isOnboarded)
        self.themeMode = ThemeMode(rawValue: defaults.string(forKey: Keys.themeMode) ?? "system") ?? .system
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.biometricEnabled = defaults.bool(forKey: Keys.biometricEnabled)
        self.autoSaveEnabled = defaults.object(forKey: Keys.autoSaveEnabled) as? Bool ?? true
        self.lastSyncTime = defaults.object(forKey: Keys.lastSyncTime) as? Date
    }

    // MARK: - Methods

    /// Clear all preferences and reset to defaults
    func clearAll() {
        userName = "User"
        isOnboarded = false
        themeMode = .system
        notificationsEnabled = true
        biometricEnabled = false
        autoSaveEnabled = true
        lastSyncTime = nil

        // Also clear from UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }

    /// Get greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default: return "Good night"
        }
    }

    /// Full greeting with user name
    var fullGreeting: String {
        "\(greeting), \(userName)"
    }
}

// MARK: - App Storage Property Wrapper Extension
extension UserDefaults {
    @objc dynamic var user_name: String {
        get { string(forKey: "user_name") ?? "User" }
        set { set(newValue, forKey: "user_name") }
    }
}
