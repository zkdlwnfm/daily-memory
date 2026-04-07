import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showRecordSheet = false
    var refreshTrigger: UUID = UUID()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.recentMemories.isEmpty && !viewModel.isLoading {
                    HomeEmptyStateView(onStartRecording: { showRecordSheet = true })
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Greeting Section
                            greetingSection

                            // Streak card
                            if viewModel.streakDays > 0 {
                                StreakCard(days: viewModel.streakDays)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                            }

                            // Daily prompt (if no memory today)
                            if viewModel.todayMemoryCount == 0 {
                                DailyPromptCard(onRecord: { showRecordSheet = true })
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                            }

                            // Reminder Card
                            if let reminder = viewModel.reminder {
                                ReminderCard(
                                    reminder: reminder,
                                    onDone: { viewModel.onReminderDone(reminder.id) },
                                    onSnooze: { viewModel.onReminderSnooze(reminder.id) }
                                )
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                            }

                            // Mood Trend
                            if !viewModel.moodData.isEmpty {
                                MoodTrendView(moodData: viewModel.moodData)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                            }

                            // Recent Memories Section
                            recentMemoriesSection

                            // Memory Cards
                            ForEach(viewModel.recentMemories) { memory in
                                NavigationLink(destination: MemoryDetailView(memoryId: memory.id)) {
                                    MemoryCard(memory: memory)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 6)
                            }

                            // On This Day Section
                            if let flashback = viewModel.flashback {
                                onThisDaySection(flashback: flashback)
                                    .padding(.top, 24)
                            }

                            Spacer(minLength: 100)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: refreshTrigger) { _ in
                Task {
                    await viewModel.refresh()
                }
            }
            .sheet(isPresented: $showRecordSheet) {
                RecordView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .memoryChanged)) { _ in
                Task { await viewModel.refresh() }
            }
        }
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.greeting), \(viewModel.userName) 👋")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("\(viewModel.todayMemoryCount) memories today · \(viewModel.reminderCount) reminder")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Recent Memories Section Header
    private var recentMemoriesSection: some View {
        HStack {
            Text("📝 Recent Memories")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            NavigationLink(destination: AllMemoriesView()) {
                Text("See all ›")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dmPrimary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - On This Day Section
    private func onThisDaySection(flashback: FlashbackUi) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📸 On this day, 1 year ago")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 24)

            FlashbackCard(flashback: flashback)
                .padding(.horizontal, 24)
        }
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    let reminder: ReminderUi
    let onDone: () -> Void
    let onSnooze: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: reminder.iconName)
                    .font(.title2)
                    .foregroundColor(Color(hex: "EA580C"))

                Text(reminder.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "431407"))
            }

            Text(reminder.description)
                .font(.subheadline)
                .foregroundColor(Color(hex: "78350F"))

            HStack(spacing: 12) {
                Button(action: onDone) {
                    Text("DONE")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(Color(hex: "431407"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "EA580C").opacity(0.3), lineWidth: 1)
                        )
                }

                Button(action: onSnooze) {
                    Text("SNOOZE")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.dmPrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color(hex: "FFF7ED"))
        .cornerRadius(16)
    }
}

// MARK: - Memory Card
struct MemoryCard: View {
    let memory: MemoryUi

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(memory.formattedDate.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.dmPrimary.opacity(0.7))
                .tracking(1)

            Text(memory.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)

            if !memory.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(memory.tags) { tag in
                            HomeTagChip(tag: tag)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }
}

// MARK: - Tag Chip
private struct HomeTagChip: View {
    let tag: TagUi

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.iconName)
                .font(.caption2)

            Text(tag.label)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .foregroundColor(.secondary)
        .cornerRadius(20)
    }
}

// MARK: - Flashback Card
struct FlashbackCard: View {
    let flashback: FlashbackUi

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            AsyncImage(url: URL(string: flashback.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(16/10, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 180)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(flashback.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(flashback.date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
        }
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

// MARK: - View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published private(set) var userName: String

    private let userPreferences = UserPreferences.shared
    @Published var todayMemoryCount = 0
    @Published var reminderCount = 0
    @Published var streakDays = 0
    @Published var reminder: ReminderUi?
    @Published var recentMemories: [MemoryUi] = []
    @Published var moodData: [MoodDataPoint] = []
    @Published var flashback: FlashbackUi?
    @Published var error: String?

    // Use Cases
    private let getRecentMemoriesUseCase: GetRecentMemoriesUseCase
    private let getTodayRemindersUseCase: GetTodayRemindersUseCase
    private let completeReminderUseCase: CompleteReminderUseCase
    private let snoozeReminderUseCase: SnoozeReminderUseCase
    private let searchMemoriesUseCase: SearchMemoriesUseCase

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default: return "Good night"
        }
    }

    init(
        getRecentMemoriesUseCase: GetRecentMemoriesUseCase = DIContainer.shared.getRecentMemoriesUseCase,
        getTodayRemindersUseCase: GetTodayRemindersUseCase = DIContainer.shared.getTodayRemindersUseCase,
        completeReminderUseCase: CompleteReminderUseCase = DIContainer.shared.completeReminderUseCase,
        snoozeReminderUseCase: SnoozeReminderUseCase = DIContainer.shared.snoozeReminderUseCase,
        searchMemoriesUseCase: SearchMemoriesUseCase = DIContainer.shared.searchMemoriesUseCase
    ) {
        self.getRecentMemoriesUseCase = getRecentMemoriesUseCase
        self.getTodayRemindersUseCase = getTodayRemindersUseCase
        self.completeReminderUseCase = completeReminderUseCase
        self.snoozeReminderUseCase = snoozeReminderUseCase
        self.searchMemoriesUseCase = searchMemoriesUseCase
        self.userName = userPreferences.userName

        Task {
            await loadData()
        }
    }

    func updateUserName() {
        userName = userPreferences.userName
    }

    func loadData() async {
        isLoading = true

        do {
            // Load recent memories
            let memories = try await getRecentMemoriesUseCase.execute(limit: 5)

            // Count today's memories
            let today = Calendar.current.startOfDay(for: Date())
            todayMemoryCount = memories.filter {
                Calendar.current.isDate($0.recordedAt, inSameDayAs: today)
            }.count

            // Convert to UI models
            recentMemories = memories.map { $0.toMemoryUi() }

            // Load today's reminders
            let reminders = try await getTodayRemindersUseCase.execute()
            reminderCount = reminders.count

            // Get first active reminder
            if let firstReminder = reminders.first(where: { $0.isActive && $0.triggeredAt == nil }) {
                reminder = firstReminder.toReminderUi()
            } else {
                reminder = nil
            }

            // Calculate streak
            streakDays = calculateStreak(memories: memories)

            // Build mood trend (last 7 with mood data)
            moodData = memories
                .filter { $0.moodScore != nil }
                .prefix(7)
                .reversed()
                .map { MoodDataPoint(date: $0.recordedAt, score: $0.moodScore ?? 5, mood: $0.mood ?? "neutral") }

            // Load flashback (1 year ago)
            flashback = await loadFlashback()

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func calculateStreak(memories: [Memory]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check if today has a memory
        let hasTodayMemory = memories.contains { calendar.isDate($0.recordedAt, inSameDayAs: checkDate) }
        if hasTodayMemory {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        // Check consecutive past days
        for _ in 0..<30 { // Max 30 days check
            let hasMemory = memories.contains { calendar.isDate($0.recordedAt, inSameDayAs: checkDate) }
            if hasMemory {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    private func loadFlashback() async -> FlashbackUi? {
        let calendar = Calendar.current
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -3, to: oneYearAgo),
              let endDate = calendar.date(byAdding: .day, value: 3, to: oneYearAgo) else {
            return nil
        }

        do {
            let memories = try await searchMemoriesUseCase.byDateRange(from: startDate, to: endDate)
            if let memory = memories.first(where: { !$0.photos.isEmpty }) ?? memories.first {
                return memory.toFlashbackUi()
            }
        } catch {
            // Ignore errors for flashback
        }
        return nil
    }

    func refresh() async {
        await loadData()
    }

    func onReminderDone(_ id: String) {
        Task {
            do {
                try await completeReminderUseCase.execute(reminderId: id)
                reminder = nil
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func onReminderSnooze(_ id: String, minutes: Int = 30) {
        Task {
            do {
                try await snoozeReminderUseCase.execute(reminderId: id, snoozeMinutes: minutes)
                reminder = nil
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func clearError() {
        error = nil
    }
}

// MARK: - Domain to UI Model Extensions
private extension Memory {
    func toMemoryUi() -> MemoryUi {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let daysDiff = Calendar.current.dateComponents([.day], from: recordedAt, to: Date()).day ?? 0

        let formattedDate: String
        switch daysDiff {
        case 0:
            formattedDate = "Today, \(formatter.string(from: recordedAt))"
        case 1:
            formattedDate = "Yesterday, \(formatter.string(from: recordedAt))"
        case 2..<7:
            formattedDate = "\(daysDiff) days ago"
        default:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            formattedDate = dateFormatter.string(from: recordedAt)
        }

        var tags: [TagUi] = []
        for (index, person) in extractedPersons.enumerated() {
            tags.append(TagUi(id: "p\(index)", type: .person, label: person))
        }
        if let location = extractedLocation {
            tags.append(TagUi(id: "loc", type: .location, label: location))
        }
        if let amount = extractedAmount {
            tags.append(TagUi(id: "amt", type: .financial, label: "$\(Int(amount))"))
        }

        return MemoryUi(
            id: id,
            content: content,
            formattedDate: formattedDate,
            tags: tags
        )
    }

    func toFlashbackUi() -> FlashbackUi {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"

        return FlashbackUi(
            id: id,
            title: String(content.prefix(50)) + (content.count > 50 ? "..." : ""),
            date: formatter.string(from: recordedAt),
            imageUrl: photos.first?.url
        )
    }
}

private extension Reminder {
    func toReminderUi() -> ReminderUi {
        let type: ReminderUi.ReminderType
        if personId != nil {
            type = .birthday
        } else if title.lowercased().contains("meeting") {
            type = .meeting
        } else if title.lowercased().contains("payment") || title.lowercased().contains("money") {
            type = .financial
        } else {
            type = .general
        }

        return ReminderUi(
            id: id,
            title: title,
            description: body,
            type: type
        )
    }
}

// MARK: - UI Models
struct ReminderUi: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ReminderType

    var iconName: String {
        switch type {
        case .birthday: return "birthday.cake"
        case .event: return "calendar"
        case .meeting: return "person.2"
        case .financial: return "dollarsign.circle"
        case .general: return "bell"
        }
    }

    enum ReminderType {
        case birthday, event, meeting, financial, general
    }
}

struct MemoryUi: Identifiable {
    let id: String
    let content: String
    let formattedDate: String
    let tags: [TagUi]
}

struct TagUi: Identifiable {
    let id: String
    let type: TagType
    let label: String

    var iconName: String {
        switch type {
        case .person: return "person"
        case .location: return "location"
        case .financial: return "creditcard"
        case .event: return "calendar"
        case .general: return "tag"
        }
    }

    enum TagType {
        case person, location, financial, event, general
    }
}

struct FlashbackUi: Identifiable {
    let id: String
    let title: String
    let date: String
    let imageUrl: String?
}

#Preview {
    HomeView()
}
