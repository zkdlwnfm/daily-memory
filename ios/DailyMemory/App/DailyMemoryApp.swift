import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Push notifications
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // FCM token received - subscribe to user topic
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        subscribeToUserTopic()
    }

    func subscribeToUserTopic() {
        guard let uid = AuthService.shared.currentUserId else { return }
        let topic = "user_\(uid)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
            } else {
            }
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}

@main
struct DailyMemoryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var persistenceController = PersistenceController.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @StateObject private var authService = AuthService.shared
    @StateObject private var syncManager = SyncManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(deepLinkHandler)
                .environmentObject(authService)
                .environmentObject(syncManager)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
        }
    }
}

/// Root view that switches between auth and main content
struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var skippedSignIn = UserDefaults.standard.bool(forKey: "skippedSignIn")
    @State private var isOnboardingCompleted = UserPreferences.shared.isOnboarded

    var body: some View {
        Group {
            if !isOnboardingCompleted {
                OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
            } else {
                switch authService.authState {
                case .unknown:
                    ProgressView("Loading...")

                case .signedIn:
                    ContentView()

                case .signedOut:
                    if skippedSignIn {
                        ContentView()
                    } else {
                        LoginView()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .skipSignIn)) { notification in
            if let value = notification.object as? Bool {
                skippedSignIn = value
            } else {
                skippedSignIn = true
            }
        }
    }
}

// MARK: - Deep Link Handler
/// Handles deep links from widgets and other sources
class DeepLinkHandler: ObservableObject {
    @Published var shouldShowRecordSheet = false
    @Published var recordMode: RecordMode = .voice

    enum RecordMode {
        case voice
        case text
    }

    func handle(url: URL) {
        guard url.scheme == "dailymemory" else { return }

        switch url.host {
        case "record":
            // Parse mode from query parameters
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let modeParam = components.queryItems?.first(where: { $0.name == "mode" })?.value {
                recordMode = modeParam == "text" ? .text : .voice
            } else {
                recordMode = .voice
            }
            shouldShowRecordSheet = true

        default:
            // 위젯 탭 등 호스트 없는 딥링크 → 바로 녹음
            recordMode = .voice
            shouldShowRecordSheet = true
        }
    }
}
