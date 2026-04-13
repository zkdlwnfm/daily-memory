import SwiftUI

struct ContentView: View {
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @State private var selectedTab: Tab = .home
    @State private var showRecordSheet = false
    @State private var homeRefreshTrigger = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(refreshTrigger: homeRefreshTrigger)
                    .tag(Tab.home)

                SearchView()
                    .tag(Tab.search)

                ChatView()
                    .tag(Tab.chat)

                SettingsView()
                    .tag(Tab.settings)
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, showRecordSheet: $showRecordSheet)
        }
        .sheet(isPresented: $showRecordSheet) {
            RecordView(autoStartRecording: deepLinkHandler.autoStartRecording)
        }
        .onChange(of: showRecordSheet) { isShowing in
            if !isShowing {
                homeRefreshTrigger = UUID()
                deepLinkHandler.autoStartRecording = false
            }
        }
        // Refresh home when switching back to home tab
        .onChange(of: selectedTab) { tab in
            if tab == .home {
                homeRefreshTrigger = UUID()
            }
        }
        // Handle deep links from widgets
        .onChange(of: deepLinkHandler.shouldShowRecordSheet) { newValue in
            if newValue {
                showRecordSheet = true
                // Reset the flag
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    deepLinkHandler.shouldShowRecordSheet = false
                }
            }
        }
    }
}

enum Tab: String, CaseIterable {
    case home = "Home"
    case search = "Search"
    case chat = "Chat"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .chat: return "bubble.left.and.bubble.right"
        case .settings: return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showRecordSheet: Bool

    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
                Spacer()

                if tab == .search {
                    // FAB in the middle
                    Spacer()
                    Button(action: { showRecordSheet = true }) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.dmPrimary)
                            .clipShape(Circle())
                            .shadow(color: Color.dmPrimary.opacity(0.3), radius: 8, y: 4)
                    }
                    .offset(y: -20)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        )
    }
}

struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                Text(tab.rawValue)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .dmPrimary : .secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkHandler())
}
