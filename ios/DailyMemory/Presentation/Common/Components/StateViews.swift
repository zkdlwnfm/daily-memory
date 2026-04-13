import SwiftUI

// MARK: - Loading State
struct LoadingView: View {
    var message: String?

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            if let message {
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
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 88, height: 88)

                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 68, height: 68)

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.red.opacity(0.7))
            }

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm + 4)
                        .background(Color.dmPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(Radius.md)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
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

// MARK: - Empty State (Illustrated)
struct EmptyStateView: View {
    let title: String
    let message: String
    var emoji: String?
    var icon: String?
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Illustrated icon with layered circles
            ZStack {
                Circle()
                    .fill(Color.dmPrimary.opacity(0.05))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.dmPrimary.opacity(0.08))
                    .frame(width: 88, height: 88)

                if let emoji {
                    Text(emoji)
                        .font(.system(size: 40))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(.dmPrimary.opacity(0.6))
                }
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            if let actionLabel, let onAction {
                Button(action: onAction) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(actionLabel)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm + 4)
                    .background(Color.dmPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(Radius.lg)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
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
            message: "No matches for \"\(query)\".\nTry a different search term.",
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
                title: "Start your journey",
                message: "Record your first memory.\nEngram will organize your thoughts with AI.",
                icon: "brain.head.profile",
                actionLabel: onAddMemory != nil ? "Record Memory" : nil,
                onAction: onAddMemory
            )
        }
    }

    struct PeopleEmpty: View {
        var onAddPerson: (() -> Void)?

        var body: some View {
            EmptyStateView(
                title: "People you mention",
                message: "When you record memories, AI automatically discovers the people in your life.",
                icon: "person.2.fill",
                actionLabel: onAddPerson != nil ? "Add Person" : nil,
                onAction: onAddPerson
            )
        }
    }

    struct RemindersEmpty: View {
        var onAddReminder: (() -> Void)?

        var body: some View {
            EmptyStateView(
                title: "All caught up!",
                message: "No reminders right now.\nAdd one to stay on top of important things.",
                icon: "bell.badge.fill",
                actionLabel: onAddReminder != nil ? "Add Reminder" : nil,
                onAction: onAddReminder
            )
        }
    }

    struct TimelineEmpty: View {
        var body: some View {
            EmptyStateView(
                title: "No memories yet",
                message: "Memories with this person will appear here over time.",
                icon: "clock.fill"
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
