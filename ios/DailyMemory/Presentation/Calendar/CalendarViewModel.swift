import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedMonth: Date = Date()
    @Published var selectedDate: Date? = nil
    @Published var eventsByDate: [Date: [CalendarEvent]] = [:]
    @Published var systemEvents: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var error: String?

    private let getCalendarEventsUseCase: GetCalendarEventsUseCase
    private let syncSystemCalendarUseCase: SyncSystemCalendarUseCase

    init(
        getCalendarEventsUseCase: GetCalendarEventsUseCase = DIContainer.shared.getCalendarEventsUseCase,
        syncSystemCalendarUseCase: SyncSystemCalendarUseCase = DIContainer.shared.syncSystemCalendarUseCase
    ) {
        self.getCalendarEventsUseCase = getCalendarEventsUseCase
        self.syncSystemCalendarUseCase = syncSystemCalendarUseCase

        Task { await loadMonth() }
    }

    // MARK: - Computed

    /// Events for the currently selected date
    var selectedDateEvents: [CalendarEvent] {
        guard let date = selectedDate else { return [] }
        let key = Calendar.current.startOfDay(for: date)
        return eventsByDate[key] ?? []
    }

    /// Month/year display string
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    /// Whether the selected month contains today
    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Actions

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func navigateMonth(offset: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) else { return }
        selectedMonth = newMonth
        selectedDate = nil
        Task { await loadMonth() }
    }

    func goToToday() {
        selectedMonth = Date()
        selectedDate = Date()
        Task { await loadMonth() }
    }

    func loadMonth() async {
        isLoading = true
        let calendar = Calendar.current

        // Calculate month date range
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            isLoading = false
            return
        }

        let from = monthInterval.start
        let to = monthInterval.end

        do {
            // Load app events
            let events = try await getCalendarEventsUseCase.execute(from: from, to: to)
            eventsByDate = events

            // Load system calendar events
            let sysEvents = await syncSystemCalendarUseCase.execute(from: from, to: to)
            for event in sysEvents {
                let key = calendar.startOfDay(for: event.date)
                eventsByDate[key, default: []].append(event)
            }

            // Sort all day events
            for (date, dayEvents) in eventsByDate {
                eventsByDate[date] = dayEvents.sorted { $0.date < $1.date }
            }

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func requestCalendarAccess() async {
        let granted = await syncSystemCalendarUseCase.requestAccess()
        if granted {
            await loadMonth()
        }
    }

    /// Dot types for a specific date (for rendering colored dots)
    func dotTypes(for date: Date) -> [CalendarEvent.CalendarEventType] {
        let key = Calendar.current.startOfDay(for: date)
        guard let events = eventsByDate[key] else { return [] }

        var types: Set<String> = []
        var result: [CalendarEvent.CalendarEventType] = []

        for event in events {
            if types.insert(event.type.rawValue).inserted {
                result.append(event.type)
            }
        }
        return result
    }
}
