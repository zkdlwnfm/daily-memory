import UserNotifications
import UIKit

/// Service for managing local notifications
actor NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Request notification permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Check if notification permission is granted
    func hasPermission() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Reminder

    /// Schedule a reminder notification
    func scheduleReminder(_ reminder: Reminder) async {
        guard reminder.isActive else { return }
        guard reminder.scheduledAt > Date() else { return }

        // Check permission
        guard await hasPermission() else {
            _ = await requestPermission()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.categoryIdentifier = "REMINDER"
        content.userInfo = [
            "reminderId": reminder.id,
            "memoryId": reminder.memoryId ?? "",
            "personId": reminder.personId ?? ""
        ]

        // Create trigger based on scheduled time
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.scheduledAt
        )

        let trigger: UNNotificationTrigger

        switch reminder.repeatType {
        case .none:
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        case .daily:
            let dailyComponents = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
            trigger = UNCalendarNotificationTrigger(dateMatching: dailyComponents, repeats: true)

        case .weekly:
            var weeklyComponents = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
            weeklyComponents.weekday = Calendar.current.component(.weekday, from: reminder.scheduledAt)
            trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)

        case .monthly:
            var monthlyComponents = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
            monthlyComponents.day = Calendar.current.component(.day, from: reminder.scheduledAt)
            trigger = UNCalendarNotificationTrigger(dateMatching: monthlyComponents, repeats: true)

        case .yearly:
            var yearlyComponents = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
            yearlyComponents.month = Calendar.current.component(.month, from: reminder.scheduledAt)
            yearlyComponents.day = Calendar.current.component(.day, from: reminder.scheduledAt)
            trigger = UNCalendarNotificationTrigger(dateMatching: yearlyComponents, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: reminder.id,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    /// Cancel a scheduled reminder
    func cancelReminder(_ reminderId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderId])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [reminderId])
    }

    /// Cancel all reminders
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Snooze

    /// Snooze a reminder for specified minutes
    func snoozeReminder(_ reminder: Reminder, minutes: Int = 15) async {
        // Cancel original
        cancelReminder(reminder.id)

        // Create snoozed reminder
        var snoozedReminder = reminder
        snoozedReminder.scheduledAt = Date().addingTimeInterval(Double(minutes * 60))

        await scheduleReminder(snoozedReminder)
    }

    // MARK: - Birthday Reminders

    /// Schedule a birthday reminder for a person
    /// Note: Requires birthday field to be added to Person model
    func scheduleBirthdayReminder(for person: Person) async {
        // TODO: Implement when birthday field is added to Person model
    }

    /// Cancel birthday reminder for a person
    func cancelBirthdayReminder(for personId: String) {
        cancelReminder("birthday-\(personId)")
    }

    // MARK: - Notification Categories

    /// Setup notification categories and actions
    func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE",
            title: "Done",
            options: .foreground
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze",
            options: []
        )

        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([reminderCategory])
    }

    // MARK: - Pending Reminders

    /// Get all pending notification requests
    func getPendingReminders() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    /// Check if a specific reminder is scheduled
    func isReminderScheduled(_ reminderId: String) async -> Bool {
        let pending = await getPendingReminders()
        return pending.contains { $0.identifier == reminderId }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let reminderId = userInfo["reminderId"] as? String

        switch response.actionIdentifier {
        case "COMPLETE":
            if let reminderId = reminderId {
                Task {
                    let completeUseCase = DIContainer.shared.completeReminderUseCase
                    try? await completeUseCase.execute(reminderId: reminderId)
                }
            }

        case "SNOOZE":
            if let reminderId = reminderId {
                Task {
                    let snoozeUseCase = DIContainer.shared.snoozeReminderUseCase
                    try? await snoozeUseCase.execute(reminderId: reminderId, snoozeMinutes: 15)
                }
            }

        case UNNotificationDefaultActionIdentifier:
            if let reminderId = reminderId {
                NotificationCenter.default.post(
                    name: .openReminder,
                    object: nil,
                    userInfo: ["reminderId": reminderId]
                )
            }

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openReminder = Notification.Name("openReminder")
    static let memoryChanged = Notification.Name("memoryChanged")
}
