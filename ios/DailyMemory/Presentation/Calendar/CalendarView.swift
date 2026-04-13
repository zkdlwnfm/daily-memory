import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Month grid
                    MonthGridView(viewModel: viewModel)
                        .padding(.horizontal, 16)

                    // Legend
                    legendView
                        .padding(.horizontal, 16)

                    // Day detail (if date selected)
                    if let selectedDate = viewModel.selectedDate {
                        DayDetailView(
                            date: selectedDate,
                            events: viewModel.selectedDateEvents
                        )
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadMonth()
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedDate)
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: .blue, label: "Memory")
            legendItem(color: .orange, label: "Task")
            legendItem(color: .green, label: "Reminder")
            legendItem(color: .gray, label: "Calendar")
            Spacer()
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CalendarView()
}
