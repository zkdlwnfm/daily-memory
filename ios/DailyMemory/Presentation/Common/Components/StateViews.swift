import SwiftUI

// MARK: - Loading State
struct LoadingView: View {
    var message: String?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State
struct ErrorView: View {
    let title: String
    let message: String
    var icon: String = "exclamationmark.triangle.fill"
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.red.opacity(0.7))

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.dmPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Network Error State
struct NetworkErrorView: View {
    var onRetry: (() -> Void)?

    var body: some View {
        ErrorView(
            title: "No Internet Connection",
            message: "Please check your connection and try again.",
            icon: "wifi.slash",
            onRetry: onRetry
        )
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let title: String
    let message: String
    var emoji: String?
    var icon: String?
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 64))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let actionLabel = actionLabel, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionLabel)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.dmPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Empty State
struct SearchEmptyView: View {
    let query: String
    var onClearSearch: (() -> Void)?

    var body: some View {
        EmptyStateView(
            title: "No results found",
            message: "No matches for \"\(query)\". Try a different search term.",
            icon: "magnifyingglass",
            actionLabel: onClearSearch != nil ? "Clear Search" : nil,
            onAction: onClearSearch
        )
    }
}

// MARK: - Predefined Empty States
enum EmptyStates {
    struct MemoriesEmpty: View {
        var onAddMemory: (() -> Void)?

        var body: some View {
            EmptyStateView(
                title: "No memories yet",
                message: "Start recording your thoughts and moments. They'll appear here.",
                emoji: "\u{1F4DD}",
                actionLabel: onAddMemory != nil ? "Record Memory" : nil,
                onAction: onAddMemory
            )
        }
    }

    struct PeopleEmpty: View {
        var onAddPerson: (() -> Void)?

        var body: some View {
            EmptyStateView(
                title: "No people yet",
                message: "Record memories and AI will automatically find people, or add them manually.",
                emoji: "\u{1F465}",
                actionLabel: onAddPerson != nil ? "Add Person" : nil,
                onAction: onAddPerson
            )
        }
    }

    struct RemindersEmpty: View {
        var onAddReminder: (() -> Void)?

        var body: some View {
            EmptyStateView(
                title: "No reminders",
                message: "You're all caught up! Add reminders to stay on top of important things.",
                emoji: "\u{1F514}",
                actionLabel: onAddReminder != nil ? "Add Reminder" : nil,
                onAction: onAddReminder
            )
        }
    }

    struct TimelineEmpty: View {
        var body: some View {
            EmptyStateView(
                title: "No timeline events",
                message: "Memories with this person will appear here.",
                emoji: "\u{1F4C5}"
            )
        }
    }
}

// MARK: - Previews
#Preview("Loading") {
    LoadingView(message: "Loading memories...")
}

#Preview("Error") {
    ErrorView(
        title: "Something went wrong",
        message: "Unable to load your memories. Please try again.",
        onRetry: {}
    )
}

#Preview("Empty") {
    EmptyStates.MemoriesEmpty(onAddMemory: {})
}
