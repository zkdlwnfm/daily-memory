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
        static let recentSearches = "recent_searches"
        static let dailyPromptEnabled = "daily_prompt_enabled"
        static let quietHoursStart = "quiet_hours_start"
        static let quietHoursEnd = "quiet_hours_end"
        static let onThisDayEnabled = "on_this_day_enabled"
        static let showLockedMemories = "show_locked_memories"
        static let autoAnalyzeEnabled = "auto_analyze_enabled"
        static let smartRemindersEnabled = "smart_reminders_enabled"
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

    @Published var recentSearches: [String] {
        didSet { defaults.set(recentSearches, forKey: Keys.recentSearches) }
    }

    @Published var dailyPromptEnabled: Bool {
        didSet { defaults.set(dailyPromptEnabled, forKey: Keys.dailyPromptEnabled) }
    }

    @Published var quietHoursStart: String {
        didSet { defaults.set(quietHoursStart, forKey: Keys.quietHoursStart) }
    }

    @Published var quietHoursEnd: String {
        didSet { defaults.set(quietHoursEnd, forKey: Keys.quietHoursEnd) }
    }

    @Published var onThisDayEnabled: Bool {
        didSet { defaults.set(onThisDayEnabled, forKey: Keys.onThisDayEnabled) }
    }

    @Published var showLockedMemories: Bool {
        didSet { defaults.set(showLockedMemories, forKey: Keys.showLockedMemories) }
    }

    @Published var autoAnalyzeEnabled: Bool {
        didSet { defaults.set(autoAnalyzeEnabled, forKey: Keys.autoAnalyzeEnabled) }
    }

    @Published var smartRemindersEnabled: Bool {
        didSet { defaults.set(smartRemindersEnabled, forKey: Keys.smartRemindersEnabled) }
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
        self.recentSearches = defaults.stringArray(forKey: Keys.recentSearches) ?? []
        self.dailyPromptEnabled = defaults.object(forKey: Keys.dailyPromptEnabled) as? Bool ?? true
        self.quietHoursStart = defaults.string(forKey: Keys.quietHoursStart) ?? "10 PM"
        self.quietHoursEnd = defaults.string(forKey: Keys.quietHoursEnd) ?? "9 AM"
        self.onThisDayEnabled = defaults.object(forKey: Keys.onThisDayEnabled) as? Bool ?? true
        self.showLockedMemories = defaults.bool(forKey: Keys.showLockedMemories)
        self.autoAnalyzeEnabled = defaults.object(forKey: Keys.autoAnalyzeEnabled) as? Bool ?? true
        self.smartRemindersEnabled = defaults.object(forKey: Keys.smartRemindersEnabled) as? Bool ?? true
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
        recentSearches = []
        dailyPromptEnabled = true
        quietHoursStart = "10 PM"
        quietHoursEnd = "9 AM"
        onThisDayEnabled = true
        showLockedMemories = false
        autoAnalyzeEnabled = true
        smartRemindersEnabled = true

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
