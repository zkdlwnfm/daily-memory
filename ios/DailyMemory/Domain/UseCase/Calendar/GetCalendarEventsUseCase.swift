import Foundation

/// Use case for fetching all calendar events (memories, tasks, reminders) for a date range.
/// Merges multiple data sources into a unified CalendarEvent list.
final class GetCalendarEventsUseCase {
    private let memoryRepository: MemoryRepository
    private let taskRepository: TaskRepository
    private let reminderRepository: ReminderRepository

    init(
        memoryRepository: MemoryRepository = MemoryRepositoryImpl(),
        taskRepository: TaskRepository = TaskRepositoryImpl(),
        reminderRepository: ReminderRepository = ReminderRepositoryImpl()
    ) {
        self.memoryRepository = memoryRepository
        self.taskRepository = taskRepository
        self.reminderRepository = reminderRepository
    }

    /// Fetch all events for a date range and group by date
    func execute(from: Date, to: Date) async throws -> [Date: [CalendarEvent]] {
        async let memories = memoryRepository.getByDateRange(from: from, to: to)
        async let tasks = taskRepository.getByDateRange(from: from, to: to)
        async let reminders = reminderRepository.getAll()

        let allMemories = try await memories
        let allTasks = try await tasks
        let allReminders = try await reminders

        var events: [CalendarEvent] = []

        // Convert memories
        events.append(contentsOf: allMemories.map { CalendarEvent.from(memory: $0) })

        // Convert tasks (only those with due dates are in the range; also include undated open tasks created in range)
        events.append(contentsOf: allTasks.map { CalendarEvent.from(task: $0) })

        // Convert reminders — filter to date range
        let filteredReminders = allReminders.filter { reminder in
            reminder.scheduledAt >= from && reminder.scheduledAt <= to && reminder.isActive
        }
        events.append(contentsOf: filteredReminders.map { CalendarEvent.from(reminder: $0) })

        // Group by calendar date
        let calendar = Calendar.current
        var grouped: [Date: [CalendarEvent]] = [:]

        for event in events {
            let dateKey = calendar.startOfDay(for: event.date)
            grouped[dateKey, default: []].append(event)
        }

        // Sort events within each day by time
        for (date, dayEvents) in grouped {
            grouped[date] = dayEvents.sorted { $0.date < $1.date }
        }

        return grouped
    }
}
