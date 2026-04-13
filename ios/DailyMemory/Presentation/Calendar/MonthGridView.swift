import SwiftUI

struct MonthGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 12) {
            // Month header
            monthHeader

            // Weekday labels
            weekdayHeader

            // Date grid
            dateGrid
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Text(viewModel.monthTitle)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            if !viewModel.isCurrentMonth {
                Button("Today") {
                    viewModel.goToToday()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.dmPrimary)
            }

            HStack(spacing: 16) {
                Button { viewModel.navigateMonth(offset: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                }

                Button { viewModel.navigateMonth(offset: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Date Grid

    private var dateGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dateCellView(date: date)
                } else {
                    Color.clear.frame(height: 48)
                }
            }
        }
    }

    // MARK: - Date Cell

    private func dateCellView(date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = viewModel.selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let dots = viewModel.dotTypes(for: date)

        return Button {
            viewModel.selectDate(date)
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : (isToday ? .dmPrimary : .primary))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.dmPrimary : (isToday ? Color.dmPrimary.opacity(0.1) : Color.clear))
                    )

                // Colored dots
                HStack(spacing: 3) {
                    ForEach(Array(dots.prefix(3).enumerated()), id: \.offset) { _, type in
                        Circle()
                            .fill(colorForType(type))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.selectedMonth) else {
            return []
        }

        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: viewModel.selectedMonth)?.count ?? 30

        var days: [Date?] = []

        // Leading empty cells
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Actual days
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    private func colorForType(_ type: CalendarEvent.CalendarEventType) -> Color {
        switch type {
        case .memory: return .blue
        case .task: return .orange
        case .reminder: return .green
        case .system: return .gray
        }
    }
}
