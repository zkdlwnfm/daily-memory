import EventKit
import Foundation

/// Wrapper around EventKit for reading/writing system calendar events.
/// Calendar access is optional — the app works fully without it.
class SystemCalendarService {
    private let eventStore = EKEventStore()

    /// Whether the user has granted calendar access
    var hasAccess: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    /// Request calendar access from the user
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await eventStore.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    /// Fetch system calendar events for a date range
    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        guard hasAccess else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { ekEvent in
            CalendarEvent(
                id: "system-\(ekEvent.eventIdentifier ?? UUID().uuidString)",
                type: .system,
                title: ekEvent.title ?? "Untitled",
                subtitle: ekEvent.location,
                date: ekEvent.startDate,
                endDate: ekEvent.endDate,
                sourceId: ekEvent.eventIdentifier ?? ""
            )
        }
    }

    /// Write a task as a system calendar event
    func createEvent(title: String, date: Date, notes: String? = nil) -> Bool {
        guard hasAccess else { return false }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            return false
        }
    }
}
