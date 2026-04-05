import Foundation

enum Constants {
    // MARK: - App Info
    enum App {
        static let name = "DailyMemory"
        static let bundleId = "com.effortmoney.dailymemory"
        static let appStoreId = ""
    }

    // MARK: - API
    enum API {
        static let baseURL = "https://dailymemory.pjhdev.co.kr/api/v1"
        static let timeout: TimeInterval = 30
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let isOnboardingCompleted = "isOnboardingCompleted"
        static let selectedTheme = "selectedTheme"
        static let privacyMode = "privacyMode"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastSyncDate = "lastSyncDate"
    }

    // MARK: - Limits
    enum Limits {
        static let freeMemoriesPerMonth = 30
        static let maxPhotoAttachments = 10
        static let maxTextLength = 5000
        static let maxPersonNameLength = 100
    }

    // MARK: - Animation
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let shortDuration: Double = 0.15
        static let longDuration: Double = 0.5
    }

    // MARK: - Notifications
    enum NotificationIds {
        static let reminderCategory = "REMINDER_CATEGORY"
        static let reminderAction = "REMINDER_ACTION"
    }
}
