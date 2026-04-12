import SwiftUI

// MARK: - ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userEmail: String = ""
    @Published var displayName: String = ""
    @Published var isPremium: Bool = false
    @Published var isSignedIn: Bool = false

    // Notifications
    @Published var remindersEnabled: Bool = true {
        didSet { userPreferences.notificationsEnabled = remindersEnabled }
    }
    @Published var dailyPromptEnabled: Bool = true {
        didSet { userPreferences.dailyPromptEnabled = dailyPromptEnabled }
    }
    @Published var dailyPromptTime: String = "9 PM"

    // Privacy
    @Published var appLockEnabled: Bool = false {
        didSet { userPreferences.biometricEnabled = appLockEnabled }
    }

    // AI
    @Published var autoAnalyzeEnabled: Bool = true {
        didSet { userPreferences.autoAnalyzeEnabled = autoAnalyzeEnabled }
    }

    // App Info
    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    private let userPreferences = UserPreferences.shared
    private let authService = AuthService.shared

    init() {
        loadFromPreferences()
        loadAuthState()
    }

    private func loadFromPreferences() {
        remindersEnabled = userPreferences.notificationsEnabled
        dailyPromptEnabled = userPreferences.dailyPromptEnabled
        appLockEnabled = userPreferences.biometricEnabled
        autoAnalyzeEnabled = userPreferences.autoAnalyzeEnabled
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
    }

    func signOut() {
        _ = authService.signOut()
        UserDefaults.standard.removeObject(forKey: "skippedSignIn")
        userPreferences.clearAll()
        loadFromPreferences()
        loadAuthState()
    }

}

// MARK: - Main View
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

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
                        }
                    }

                    // AI Features Section
                    SettingsSection(title: "AI Features") {
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.dmPrimary.opacity(0.1))
                                .padding(-4)

                            SettingsCard {
                                SettingsToggleRow(
                                    icon: "sparkles",
                                    iconColor: Color.dmPrimary,
                                    iconBackground: Color.dmPrimary.opacity(0.2),
                                    title: "Auto-analyze memories",
                                    isOn: $viewModel.autoAnalyzeEnabled
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

                            SettingsLinkRow(
                                icon: "doc.text",
                                iconColor: .secondary,
                                title: "Privacy Policy",
                                url: "https://engram.pjhdev.co.kr/privacy.html"
                            )

                            Divider().padding(.leading, 76)

                            SettingsLinkRow(
                                icon: "doc.plaintext",
                                iconColor: .secondary,
                                title: "Terms of Service",
                                url: "https://engram.pjhdev.co.kr/terms.html"
                            )

                        }
                    }

                    // People Management
                    SettingsSection(title: "People") {
                        NavigationLink(destination: PersonListView()) {
                            SettingsCard {
                                HStack(spacing: 16) {
                                    IconBox(icon: "person.2.fill", color: .blue)
                                    Text("Manage People")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                            }
                        }
                        .buttonStyle(.plain)
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

// MARK: - Settings Link Row
struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let url: String

    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 16) {
                IconBox(icon: icon, color: iconColor)
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
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
