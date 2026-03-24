import WidgetKit
import SwiftUI

/// Medium Widget (2x2 / systemMedium)
///
/// Full-featured widget showing:
/// - Date and memory count header
/// - Recent memory preview or reminders
/// - Voice and Text recording buttons
struct DailyMemoryWidget: Widget {
    let kind: String = "DailyMemoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyMemoryProvider()) { entry in
            DailyMemoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("DailyMemory")
        .description("Quick access to recording and recent memories")
        .supportedFamilies([.systemMedium])
    }
}

struct DailyMemoryWidgetView: View {
    let entry: DailyMemoryEntry

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 24)
                    .fill(WidgetColors.surface)

                HStack(spacing: 12) {
                    // Left Section - Date, Reminders/Memory
                    VStack(alignment: .leading, spacing: 8) {
                        // Header
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formattedDate)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(WidgetColors.textPrimary)

                            Text("\(entry.memoryCount) memories")
                                .font(.system(size: 12))
                                .foregroundColor(WidgetColors.textSecondary)
                        }

                        // Content Card
                        if !entry.reminders.isEmpty {
                            ReminderCard(reminders: entry.reminders)
                        } else if let memory = entry.recentMemory {
                            MemoryPreviewCard(memory: memory)
                        } else {
                            EmptyStateCard()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right Section - Action Buttons
                    VStack(spacing: 8) {
                        // Voice Button
                        Link(destination: URL(string: "dailymemory://record?mode=voice")!) {
                            VStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                Text("Voice")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(WidgetColors.primary)
                            .cornerRadius(16)
                        }

                        // Text Button
                        Link(destination: URL(string: "dailymemory://record?mode=text")!) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 20))
                                Text("Text")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(WidgetColors.textPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(WidgetColors.background)
                            .cornerRadius(16)
                        }
                    }
                    .frame(width: 80)
                }
                .padding(16)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    let reminders: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 11))
                Text("Reminders")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(WidgetColors.warning)

            ForEach(reminders.prefix(2), id: \.self) { reminder in
                Text("• \(reminder)")
                    .font(.system(size: 11))
                    .foregroundColor(WidgetColors.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WidgetColors.warningBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Memory Preview Card
struct MemoryPreviewCard: View {
    let memory: String

    var body: some View {
        Text(memory)
            .font(.system(size: 12))
            .foregroundColor(WidgetColors.textSecondary)
            .lineLimit(3)
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(WidgetColors.background)
            .cornerRadius(12)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "memories")
                .font(.system(size: 20))
                .foregroundColor(WidgetColors.textSecondary)
            Text("No memories yet")
                .font(.system(size: 11))
                .foregroundColor(WidgetColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetColors.background)
        .cornerRadius(12)
    }
}

// Preview removed - requires iOS 17+
