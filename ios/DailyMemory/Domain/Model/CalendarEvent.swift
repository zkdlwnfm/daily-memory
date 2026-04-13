import Foundation

/// Unified view model for calendar display — merges Memory, Task, and Reminder
/// Not persisted; constructed on-the-fly from domain entities.
struct CalendarEvent: Identifiable {
    let id: String
    let type: CalendarEventType
    let title: String
    let subtitle: String?
    let date: Date
    let endDate: Date?
    let sourceId: String          // original entity id

    /// Type of calendar event, determines display color
    enum CalendarEventType: String {
        case memory    // blue
        case task      // orange
        case reminder  // green
        case system    // gray (Apple Calendar)
    }

    /// Create from a Memory
    static func from(memory: Memory) -> CalendarEvent {
        CalendarEvent(
            id: "memory-\(memory.id)",
            type: .memory,
            title: memory.content.prefix(80).trimmingCharacters(in: .whitespaces),
            subtitle: memory.category.displayName,
            date: memory.recordedAt,
            endDate: nil,
            sourceId: memory.id
        )
    }

    /// Create from a Task
    static func from(task: MemoryTask) -> CalendarEvent {
        CalendarEvent(
            id: "task-\(task.id)",
            type: .task,
            title: task.title,
            subtitle: task.status.displayName,
            date: task.dueDate ?? task.createdAt,
            endDate: nil,
            sourceId: task.id
        )
    }

    /// Create from a Reminder
    static func from(reminder: Reminder) -> CalendarEvent {
        CalendarEvent(
            id: "reminder-\(reminder.id)",
            type: .reminder,
            title: reminder.title,
            subtitle: reminder.body,
            date: reminder.scheduledAt,
            endDate: nil,
            sourceId: reminder.id
        )
    }
}
