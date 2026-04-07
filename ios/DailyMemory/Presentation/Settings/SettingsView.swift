import SwiftUI

// MARK: - ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userEmail: String = ""
    @Published var displayName: String = ""
    @Published var isPremium: Bool = false
    @Published var isSignedIn: Bool = false
    @Published var lastSyncTimeDisplay: String = "Never"
    @Published var syncStateText: String = ""
    @Published var pendingChangesCount: Int = 0

    // Notifications
    @Published var remindersEnabled: Bool = true {
        didSet { userPreferences.notificationsEnabled = remindersEnabled }
    }
    @Published var dailyPromptEnabled: Bool = true {
        didSet { userPreferences.dailyPromptEnabled = dailyPromptEnabled }
    }
    @Published var dailyPromptTime: String = "9 PM"
    @Published var quietHoursStart: String = "10 PM" {
        didSet { userPreferences.quietHoursStart = quietHoursStart }
    }
    @Published var quietHoursEnd: String = "9 AM" {
        didSet { userPreferences.quietHoursEnd = quietHoursEnd }
    }
    @Published var onThisDayEnabled: Bool = true {
        didSet { userPreferences.onThisDayEnabled = onThisDayEnabled }
    }

    // Privacy
    @Published var appLockEnabled: Bool = false {
        didSet { userPreferences.biometricEnabled = appLockEnabled }
    }
    @Published var showLockedMemories: Bool = false {
        didSet { userPreferences.showLockedMemories = showLockedMemories }
    }

    // AI
    @Published var autoAnalyzeEnabled: Bool = true {
        didSet { userPreferences.autoAnalyzeEnabled = autoAnalyzeEnabled }
    }
    @Published var smartRemindersEnabled: Bool = true {
        didSet { userPreferences.smartRemindersEnabled = smartRemindersEnabled }
    }

    // App Info
    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    private let userPreferences = UserPreferences.shared
    private let authService = AuthService.shared
    private let syncManager = SyncManager.shared

    init() {
        loadFromPreferences()
        loadAuthState()
    }

    private func loadFromPreferences() {
        remindersEnabled = userPreferences.notificationsEnabled
        dailyPromptEnabled = userPreferences.dailyPromptEnabled
        quietHoursStart = userPreferences.quietHoursStart
        quietHoursEnd = userPreferences.quietHoursEnd
        onThisDayEnabled = userPreferences.onThisDayEnabled
        appLockEnabled = userPreferences.biometricEnabled
        showLockedMemories = userPreferences.showLockedMemories
        autoAnalyzeEnabled = userPreferences.autoAnalyzeEnabled
        smartRemindersEnabled = userPreferences.smartRemindersEnabled
        updateSyncTimeDisplay()
    }

    private func loadAuthState() {
        if let profile = authService.currentUser {
            isSignedIn = true
            userEmail = profile.email ?? ""
            displayName = profile.displayName ?? ""
            isPremium = profile.isPremium
        } else {
            isSignedIn = false
            userEmail = "Not signed in"
            displayName = ""
        }
        pendingChangesCount = syncManager.pendingChanges
    }

    private func updateSyncTimeDisplay() {
        if let date = syncManager.lastSyncDate ?? userPreferences.lastSyncTime {
            let formatter = RelativeDateTimeFormatter()
            lastSyncTimeDisplay = formatter.localizedString(for: date, relativeTo: Date())
        } else {
            lastSyncTimeDisplay = "Never"
        }
    }

    func syncNow() {
        Task {
            await syncManager.syncAll()
            updateSyncTimeDisplay()
            pendingChangesCount = syncManager.pendingChanges
        }
    }

    func signOut() {
        _ = authService.signOut()
        UserDefaults.standard.removeObject(forKey: "skippedSignIn")
        userPreferences.clearAll()
        loadFromPreferences()
        loadAuthState()
    }

    var lastSyncTime: String { lastSyncTimeDisplay }
}

// MARK: - Main View
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showPremium = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Section
                    SettingsSection(title: "Account") {
                        if viewModel.isSignedIn {
                            AccountCard(
                                email: viewModel.userEmail,
                                displayName: viewModel.displayName,
                                isPremium: viewModel.isPremium
                            )
                        } else {
                            Button {
                                UserDefaults.standard.removeObject(forKey: "skippedSignIn")
                                NotificationCenter.default.post(name: .skipSignIn, object: false)
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.accentColor.opacity(0.1))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(.accentColor)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sign In")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Text("Sync your data across devices")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(28)
                            }
                        }
                    }

                    // Premium Section
                    if !viewModel.isPremium {
                        Button { showPremium = true } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(
                                            colors: [.dmPrimary, .dmPrimaryLight],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Upgrade to Premium")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("More AI, faster sync, advanced insights")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(28)
                        }
                    }

                    // Data Section
                    SettingsSection(title: "Data") {
                        SettingsCard {
                            SettingsRowWithIcon(
                                icon: "cloud.fill",
                                iconColor: .orange,
                                title: "Storage & Cloud sync"
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithSubtitle(
                                icon: "arrow.triangle.2.circlepath",
                                iconColor: .dmPrimary,
                                title: "Sync status",
                                subtitle: viewModel.pendingChangesCount > 0
                                    ? "\(viewModel.pendingChangesCount) pending - Last: \(viewModel.lastSyncTime)"
                                    : "Last: \(viewModel.lastSyncTime)"
                            ) {
                                Button("Sync now") {
                                    viewModel.syncNow()
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.dmPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                                .disabled(!viewModel.isSignedIn)
                            }

                            Divider().padding(.leading, 76)

                            SettingsRowWithIcon(
                                icon: "square.and.arrow.up",
                                iconColor: .primary,
                                title: "Export data"
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithIcon(
                                icon: "square.and.arrow.down",
                                iconColor: .primary,
                                title: "Import data"
                            )
                        }
                    }

                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        SettingsCard {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: .orange,
                                iconBackground: Color.orange.opacity(0.1),
                                title: "Reminders",
                                isOn: $viewModel.remindersEnabled
                            )

                            Divider().padding(.leading, 76)

                            SettingsToggleRowWithSubtitle(
                                icon: "square.and.pencil",
                                iconColor: .blue,
                                iconBackground: Color.blue.opacity(0.1),
                                title: "Daily prompt",
                                subtitle: "Every day at \(viewModel.dailyPromptTime)",
                                isOn: $viewModel.dailyPromptEnabled
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithSubtitle(
                                icon: "moon.fill",
                                iconColor: .gray,
                                title: "Quiet hours",
                                subtitle: "\(viewModel.quietHoursEnd) - \(viewModel.quietHoursStart)"
                            ) {
                                Text("Set >")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.dmPrimary)
                            }

                            Divider().padding(.leading, 76)

                            SettingsToggleRow(
                                icon: "calendar",
                                iconColor: .pink,
                                iconBackground: Color.pink.opacity(0.1),
                                title: "On this day",
                                isOn: $viewModel.onThisDayEnabled
                            )
                        }
                    }

                    // Privacy & Security Section
                    SettingsSection(title: "Privacy & Security") {
                        SettingsCard {
                            SettingsToggleRow(
                                icon: "lock.fill",
                                iconColor: .green,
                                iconBackground: Color.green.opacity(0.1),
                                title: "App lock (Face ID)",
                                isOn: $viewModel.appLockEnabled
                            )

                            Divider().padding(.leading, 76)

                            SettingsToggleRow(
                                icon: "eye.slash.fill",
                                iconColor: .yellow,
                                iconBackground: Color.yellow.opacity(0.1),
                                title: "Show locked memories",
                                isOn: $viewModel.showLockedMemories
                            )
                        }
                    }

                    // AI Features Section
                    SettingsSection(title: "AI Features") {
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.1))
                                .padding(-4)

                            SettingsCard {
                                SettingsToggleRow(
                                    icon: "sparkles",
                                    iconColor: Color(red: 0.42, green: 0.22, blue: 0.83),
                                    iconBackground: Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.2),
                                    title: "Auto-analyze memories",
                                    isOn: $viewModel.autoAnalyzeEnabled
                                )

                                Divider().padding(.leading, 76)

                                SettingsToggleRow(
                                    icon: "lightbulb.fill",
                                    iconColor: Color(red: 0.42, green: 0.22, blue: 0.83),
                                    iconBackground: Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.2),
                                    title: "Smart reminder suggestions",
                                    isOn: $viewModel.smartRemindersEnabled
                                )
                            }
                        }
                    }

                    // About Section
                    SettingsSection(title: "About") {
                        SettingsCard {
                            SettingsRowWithValue(
                                icon: "info.circle",
                                iconColor: .secondary,
                                title: "Version",
                                value: viewModel.appVersion
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithIcon(
                                icon: "doc.text",
                                iconColor: .secondary,
                                title: "Privacy Policy"
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithIcon(
                                icon: "doc.plaintext",
                                iconColor: .secondary,
                                title: "Terms of Service"
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithIcon(
                                icon: "bubble.left.and.bubble.right",
                                iconColor: .secondary,
                                title: "Contact Support"
                            )

                            Divider().padding(.leading, 76)

                            SettingsRowWithIcon(
                                icon: "star",
                                iconColor: .secondary,
                                title: "Rate the App"
                            )
                        }
                    }

                    // Sign Out
                    if viewModel.isSignedIn {
                        Button(action: viewModel.signOut) {
                            Text("Sign Out")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.red.opacity(0.7))
                                .tracking(1)
                        }
                        .padding(.vertical, 16)
                    }

                    Spacer(minLength: 100)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.horizontal, 8)

            content
        }
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(.systemBackground))
        .cornerRadius(28)
    }
}

// MARK: - Account Card
struct AccountCard: View {
    let email: String
    var displayName: String = ""
    let isPremium: Bool

    var body: some View {
        Button(action: { /* Navigate to account */ }) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.dmPrimary.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.dmPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if !displayName.isEmpty {
                        Text(displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(email)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    if isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("Premium Plan")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.dmPrimary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(28)
        }
    }
}

// MARK: - Settings Row with Icon
struct SettingsRowWithIcon: View {
    let icon: String
    let iconColor: Color
    var iconBackground: Color? = nil
    let title: String

    var body: some View {
        Button(action: { /* Navigate */ }) {
            HStack(spacing: 16) {
                IconBox(icon: icon, color: iconColor, background: iconBackground)

                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(20)
        }
    }
}

// MARK: - Settings Row with Subtitle
struct SettingsRowWithSubtitle<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    var iconBackground: Color? = nil
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 16) {
            IconBox(icon: icon, color: iconColor, background: iconBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            trailing
        }
        .padding(20)
    }
}

// MARK: - Settings Row with Value
struct SettingsRowWithValue: View {
    let icon: String
    let iconColor: Color
    var iconBackground: Color? = nil
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            IconBox(icon: icon, color: iconColor, background: iconBackground)

            Text(title)
                .font(.body)
                .fontWeight(.semibold)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    var iconBackground: Color? = nil
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            IconBox(icon: icon, color: iconColor, background: iconBackground)

            Text(title)
                .font(.body)
                .fontWeight(.semibold)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.dmPrimary)
        }
        .padding(20)
    }
}

// MARK: - Settings Toggle Row with Subtitle
struct SettingsToggleRowWithSubtitle: View {
    let icon: String
    let iconColor: Color
    var iconBackground: Color? = nil
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            IconBox(icon: icon, color: iconColor, background: iconBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.dmPrimary)
        }
        .padding(20)
    }
}

// MARK: - Icon Box
struct IconBox: View {
    let icon: String
    let color: Color
    var background: Color? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(background ?? color.opacity(0.1))
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
        }
    }
}

#Preview {
    SettingsView()
}
