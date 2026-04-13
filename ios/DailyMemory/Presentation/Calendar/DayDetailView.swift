import SwiftUI

struct DayDetailView: View {
    let date: Date
    let events: [CalendarEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            HStack {
                Text(formattedDate)
                    .font(.headline)
                    .fontWeight(.bold)

                if isToday {
                    Text("Today")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.dmPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.dmPrimary.opacity(0.1))
                        .cornerRadius(6)
                }

                Spacer()

                Text("\(events.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if events.isEmpty {
                emptyState
            } else {
                eventsList
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Events List

    private var eventsList: some View {
        VStack(spacing: 0) {
            ForEach(events) { event in
                CalendarEventRow(event: event)

                if event.id != events.last?.id {
                    Divider()
                        .padding(.leading, 70)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.title)
                .foregroundColor(.secondary.opacity(0.5))

            Text("No events")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
