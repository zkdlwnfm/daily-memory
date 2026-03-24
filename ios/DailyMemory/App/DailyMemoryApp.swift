import SwiftUI

@main
struct DailyMemoryApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
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
