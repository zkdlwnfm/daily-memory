import SwiftUI

struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator dot
            Circle()
                .fill(typeColor)
                .frame(width: 8, height: 8)

            // Time
            Text(formattedTime)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Type badge
            Text(typeBadge)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(typeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(typeColor.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.date)
    }

    private var typeColor: Color {
        switch event.type {
        case .memory: return .blue
        case .task: return .orange
        case .reminder: return .green
        case .system: return .gray
        }
    }

    private var typeBadge: String {
        switch event.type {
        case .memory: return "Memory"
        case .task: return "Task"
        case .reminder: return "Reminder"
        case .system: return "Calendar"
        }
    }
}
