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
                .task {
                    await scheduleOnThisDayIfAvailable()
                }
        }
    }

    private func scheduleOnThisDayIfAvailable() async {
        let calendar = Calendar.current
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -1, to: oneYearAgo),
              let endDate = calendar.date(byAdding: .day, value: 1, to: oneYearAgo) else {
            return
        }

        let useCase = DIContainer.shared.searchMemoriesUseCase
        do {
            let memories = try await useCase.byDateRange(from: startDate, to: endDate)
            if let memory = memories.first {
                let preview = "1 year ago: \(String(memory.content.prefix(80)))..."
                await NotificationService.shared.scheduleOnThisDayNotification(memoryPreview: preview)
            }
        } catch {
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
    @Published var autoStartRecording = false

    enum RecordMode {
        case voice
        case text
    }

    func handle(url: URL) {
        guard url.scheme == "dailymemory" else { return }

        switch url.host {
        case "record":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let modeParam = components.queryItems?.first(where: { $0.name == "mode" })?.value {
                recordMode = modeParam == "text" ? .text : .voice
            } else {
                recordMode = .voice
            }
            // 위젯에서 진입 시 자동 녹음 시작
            autoStartRecording = (recordMode == .voice)
            shouldShowRecordSheet = true

        default:
            recordMode = .voice
            autoStartRecording = true
            shouldShowRecordSheet = true
        }
    }
}
