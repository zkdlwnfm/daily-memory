import SwiftUI

struct MonthGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: Spacing.md) {
            monthHeader
            weekdayHeader
            dateGrid
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.monthTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            if !viewModel.isCurrentMonth {
                Button("Today") {
                    viewModel.goToToday()
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.dmPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.dmPrimary.opacity(0.1))
                .cornerRadius(Radius.sm)
            }

            HStack(spacing: Spacing.md) {
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
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays.indices, id: \.self) { index in
                Text(weekdays[index])
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Date Grid (Heatmap)

    private var dateGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

        return LazyVGrid(columns: columns, spacing: 3) {
            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    heatmapCell(date: date)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    // MARK: - Heatmap Cell

    private func heatmapCell(date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = viewModel.selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let eventCount = viewModel.dotTypes(for: date).count
        let isFuture = date > Date()

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectDate(date)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // Heatmap background
                RoundedRectangle(cornerRadius: 8)
                    .fill(heatmapColor(count: eventCount, isFuture: isFuture))

                // Today ring
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.dmPrimary, lineWidth: 2)
                }

                // Selected state
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dmPrimary)
                }

                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .medium))
                        .foregroundColor(cellTextColor(isSelected: isSelected, isToday: isToday, isFuture: isFuture, eventCount: eventCount))

                    // Small event indicator dots
                    if eventCount > 0 && !isSelected {
                        HStack(spacing: 2) {
                            ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                                Circle()
                                    .fill(isToday ? Color.dmPrimary : Color.white.opacity(0.7))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Heatmap Colors

    private func heatmapColor(count: Int, isFuture: Bool) -> Color {
        if isFuture { return Color(.systemGray6).opacity(0.5) }

        switch count {
        case 0: return Color(.systemGray6).opacity(0.3)
        case 1: return Color.dmPrimary.opacity(0.1)
        case 2: return Color.dmPrimary.opacity(0.2)
        case 3: return Color.dmPrimary.opacity(0.3)
        default: return Color.dmPrimary.opacity(0.4)
        }
    }

    private func cellTextColor(isSelected: Bool, isToday: Bool, isFuture: Bool, eventCount: Int) -> Color {
        if isSelected { return .white }
        if isFuture { return .secondary.opacity(0.4) }
        if isToday { return .dmPrimary }
        if eventCount >= 3 { return .white }
        return .primary
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

        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }
}
