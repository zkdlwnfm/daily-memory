import SwiftUI
import FirebaseCore

@main
struct DailyMemoryApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @StateObject private var authService = AuthService.shared
    @StateObject private var syncManager = SyncManager.shared

    init() {
        FirebaseApp.configure()
    }

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
            break
        }
    }
}
