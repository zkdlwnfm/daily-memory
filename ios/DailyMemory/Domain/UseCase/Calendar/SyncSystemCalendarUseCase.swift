import Foundation

/// Use case for reading system calendar events via EventKit.
/// Returns CalendarEvent with type .system for display in the calendar view.
final class SyncSystemCalendarUseCase {
    private let calendarService: SystemCalendarService

    init(calendarService: SystemCalendarService = SystemCalendarService()) {
        self.calendarService = calendarService
    }

    /// Fetch system calendar events for a date range
    func execute(from: Date, to: Date) async -> [CalendarEvent] {
        guard calendarService.hasAccess else { return [] }
        return calendarService.fetchEvents(from: from, to: to)
    }

    /// Request calendar access permission
    func requestAccess() async -> Bool {
        await calendarService.requestAccess()
    }

    /// Check if calendar access is granted
    var hasAccess: Bool {
        calendarService.hasAccess
    }
}
