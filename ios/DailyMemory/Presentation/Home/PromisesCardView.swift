import SwiftUI

/// Card showing open promises/tasks on the Home screen.
/// Swipe left to complete, tap to navigate to source memory.
struct PromisesCardView: View {
    let tasks: [MemoryTask]
    let onComplete: (String) -> Void
    let onTapTask: (String) -> Void  // navigate to source memory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundColor(.dmPrimary)

                Text("Open Promises")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("(\(tasks.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }

            if tasks.isEmpty {
                emptyState
            } else {
                // Task list (show up to 3)
                ForEach(tasks.prefix(3)) { task in
                    taskRow(task)
                }

                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - Task Row

    private func taskRow(_ task: MemoryTask) -> some View {
        Button {
            onTapTask(task.memoryId)
        } label: {
            HStack(spacing: 12) {
                // Completion button
                Button {
                    onComplete(task.id)
                } label: {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.status == .completed ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // Task content
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(task.status == .completed ? .secondary : .primary)
                        .strikethrough(task.status == .completed)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Person badge
                        if task.personId != nil {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.dmPrimary.opacity(0.7))
                        }

                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(formattedDueDate(dueDate))
                                    .font(.caption)
                            }
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                        }

                        // Source info
                        Text("from \(relativeDate(task.createdAt))")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.secondary.opacity(0.5))
            Text("No open promises. Record a memory to get started!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Formatters

    private func formattedDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }

        let daysDiff = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysDiff < 0 { return "\(abs(daysDiff))d overdue" }
        if daysDiff <= 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func relativeDate(_ date: Date) -> String {
        let daysDiff = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch daysDiff {
        case 0: return "today"
        case 1: return "yesterday"
        default: return "\(daysDiff)d ago"
        }
    }
}
