import SwiftUI

struct PersonDetailView: View {
    let person: Person
    @ObservedObject var viewModel: PeopleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showAddMemorySheet = false
    @State private var showAllMemories = false
    @State private var personMemories: [Memory] = []
    @State private var upcomingReminders: [Reminder] = []

    private let searchMemoriesUseCase = DIContainer.shared.searchMemoriesUseCase
    private let getUpcomingRemindersUseCase = DIContainer.shared.getUpcomingRemindersUseCase

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    profileSection
                        .padding(.top, 16)

                    // Bento Grid
                    bentoGrid
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // Timeline Section
                    timelineSection
                        .padding(.top, 24)

                    Spacer(minLength: 120)
                }
            }
            .background(Color(.systemGroupedBackground))

            // Add Memory Button
            addMemoryButton
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)

                    Button(action: { /* More options */ }) {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            PersonEditView(personId: person.id)
                .onDisappear {
                    Task { await viewModel.loadPeople() }
                }
        }
        .sheet(isPresented: $showAddMemorySheet) {
            RecordView()
                .onDisappear {
                    Task { await loadPersonData() }
                }
        }
        .navigationDestination(isPresented: $showAllMemories) {
            PersonMemoriesView(person: person, memories: personMemories)
        }
        .task {
            await loadPersonData()
        }
    }

    private func loadPersonData() async {
        do {
            personMemories = try await searchMemoriesUseCase.byPerson(personId: person.id)
            upcomingReminders = try await getUpcomingRemindersUseCase.execute(limit: 5)
                .filter { $0.personId == person.id }
        } catch {
            personMemories = []
            upcomingReminders = []
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Avatar with badge
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 96, height: 96)

                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }

                // Star badge
                ZStack {
                    Circle()
                        .fill(Color.dmPrimary)
                        .frame(width: 28, height: 28)

                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
            }

            VStack(spacing: 4) {
                Text(person.name)
                    .font(.title)
                    .fontWeight(.heavy)

                Text("\(person.relationship.displayName)\(person.nickname.map { " (\($0))" } ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Bento Grid
    private var bentoGrid: some View {
        HStack(spacing: 12) {
            statsCard
            if !upcomingReminders.isEmpty {
                upcomingCard
            }
        }
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        let yearsKnown = Calendar.current.dateComponents([.year], from: person.createdAt, to: Date()).year ?? 0
        let daysAgo = person.lastMeetingDate.map {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
        } ?? 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.dmPrimary)
                Text("Relationship Summary")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Meetings this year
                HStack {
                    Text("Meetings this year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(person.meetingCount) ↑")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.dmPrimary)
                }

                // Last met
                VStack(alignment: .leading, spacing: 2) {
                    Text("LAST MET")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(1)

                    if let lastDate = person.lastMeetingDate {
                        Text("\(lastDate.formatted(.dateTime.month(.abbreviated).day())) (\(daysAgo) days ago)")
                            .font(.caption)
                            .fontWeight(.medium)
                    } else {
                        Text("Never")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                // First memory
                VStack(alignment: .leading, spacing: 2) {
                    Text("FIRST MEMORY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(1)

                    Text(person.createdAt.formatted(.dateTime.month(.wide).year()))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                // Known for
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.dmPrimary)
                    Text("Known for: \(yearsKnown > 0 ? "\(yearsKnown) years" : "< 1 year")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.dmPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.dmPrimary.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(red: 0.95, green: 0.95, blue: 1.0))
        .cornerRadius(24)
    }

    // MARK: - Upcoming Card
    private var upcomingCard: some View {
        let reminder = upcomingReminders.first

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(red: 0.42, green: 0.22, blue: 0.83))
                Text("Upcoming")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            if let reminder = reminder {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(formatReminderDate(reminder.scheduledAt))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.42, green: 0.22, blue: 0.83))
                }

                Text(reminder.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            NavigationLink(destination: ReminderEditView(personId: person.id)) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                    Text(reminder == nil ? "Add reminder" : "Edit reminder")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(Color(red: 0.42, green: 0.22, blue: 0.83))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color(red: 0.95, green: 0.93, blue: 1.0))
        .cornerRadius(24)
    }

    private func formatReminderDate(_ date: Date) -> String {
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: date)

        if daysUntil == 0 {
            return "\(dateStr) (Today)"
        } else if daysUntil == 1 {
            return "\(dateStr) (Tomorrow)"
        } else if daysUntil > 0 {
            return "\(dateStr) (in \(daysUntil) days)"
        } else {
            return "\(dateStr) (Past)"
        }
    }

    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Timeline")
                    .font(.title2)
                    .fontWeight(.heavy)

                Spacer()

                if personMemories.count > 3 {
                    Button("See all >") {
                        showAllMemories = true
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.dmPrimary)
                }
            }
            .padding(.horizontal, 24)

            // Timeline Items
            if personMemories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No memories yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(timelineItems.grouped(by: \.year).sorted(by: { $0.key > $1.key }), id: \.key) { year, items in
                        // Year Header
                        HStack(spacing: 16) {
                            Circle()
                                .fill(year == Calendar.current.component(.year, from: Date()) ? Color.dmPrimary : Color(.systemGray5))
                                .frame(width: 16, height: 16)

                            Text(String(year))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(year == Calendar.current.component(.year, from: Date()) ? .primary : .secondary.opacity(0.6))

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)

                        // Items for this year
                        ForEach(items) { item in
                            NavigationLink(destination: MemoryDetailView(memoryId: item.id)) {
                                TimelineItemRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Add Memory Button
    private var addMemoryButton: some View {
        Button(action: { showAddMemorySheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                Text("Add memory about \(person.name)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.label))
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
    }

    // MARK: - Timeline Items from Memories
    private var timelineItems: [TimelineItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return personMemories.prefix(10).map { memory in
            let year = Calendar.current.component(.year, from: memory.recordedAt)
            let dateStr = formatter.string(from: memory.recordedAt)
            let contentPreview = String(memory.content.prefix(60)) + (memory.content.count > 60 ? "..." : "")

            return TimelineItem(
                id: memory.id,
                year: year,
                date: dateStr,
                content: contentPreview
            )
        }
    }
}

// MARK: - Timeline Item
struct TimelineItem: Identifiable {
    let id: String
    let year: Int
    let date: String
    let content: String
}

struct TimelineItemRow: View {
    let item: TimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Dot
            VStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 8, height: 8)
                    .padding(.top, 8)
            }
            .frame(width: 16)

            // Card
            VStack(alignment: .leading, spacing: 4) {
                Text(item.date.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.dmPrimary)
                    .tracking(0.5)

                Text(item.content)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }
}

// MARK: - Array Extension
extension Array {
    func grouped<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [(key: T, value: [Element])] {
        Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
            .map { (key: $0.key, value: $0.value) }
    }
}

#Preview {
    NavigationStack {
        PersonDetailView(
            person: Person(
                id: "1",
                name: "Mike",
                relationship: .friend,
                meetingCount: 12,
                lastMeetingDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                createdAt: Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 1)) ?? Date()
            ),
            viewModel: PeopleViewModel()
        )
    }
}
