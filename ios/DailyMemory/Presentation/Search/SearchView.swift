import SwiftUI

// MARK: - ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var searchState: SearchState = .initial
    @Published var aiResponse: AIResponse?
    @Published var recentSearches: [String] = []
    @Published var suggestions: [Suggestion] = Suggestion.defaults

    private let searchMemoriesUseCase: SearchMemoriesUseCase
    private let userPreferences = UserPreferences.shared

    enum SearchState {
        case initial
        case searching
        case result
        case empty
    }

    init(searchMemoriesUseCase: SearchMemoriesUseCase = DIContainer.shared.searchMemoriesUseCase) {
        self.searchMemoriesUseCase = searchMemoriesUseCase
        self.recentSearches = userPreferences.recentSearches
    }

    func search() {
        guard !query.isEmpty else { return }

        searchState = .searching

        Task {
            do {
                let memories = try await searchMemoriesUseCase.byContent(query: query)

                if memories.isEmpty {
                    searchState = .empty
                    aiResponse = nil
                } else {
                    // Convert memories to RelatedMemory format
                    let relatedMemories = memories.prefix(5).map { memory -> RelatedMemory in
                        var tags: [MemoryTag] = []
                        for person in memory.extractedPersons {
                            tags.append(MemoryTag(type: "person", value: person))
                        }
                        if let location = memory.extractedLocation {
                            tags.append(MemoryTag(type: "location", value: location))
                        }

                        return RelatedMemory(
                            id: memory.id,
                            date: memory.recordedAt,
                            content: memory.content,
                            tags: tags
                        )
                    }

                    // Generate a simple AI-like response
                    let mainAnswer = "Found \(memories.count) memories matching \"\(query)\"."
                    let details = memories.first.map { "Most recent: \($0.content.prefix(100))..." }

                    let response = AIResponse(
                        mainAnswer: mainAnswer,
                        details: details,
                        highlight: nil,
                        relatedMemories: Array(relatedMemories),
                        followUpQuestions: generateFollowUpQuestions(from: memories)
                    )

                    aiResponse = response
                    searchState = .result
                }

                // Save to recent searches
                saveRecentSearch(query)

            } catch {
                searchState = .empty
                aiResponse = nil
            }
        }
    }

    private func generateFollowUpQuestions(from memories: [Memory]) -> [String] {
        var questions: [String] = []

        // Extract unique persons
        let persons = Set(memories.flatMap { $0.extractedPersons })
        if let person = persons.first {
            questions.append("More about \(person)?")
        }

        // Extract unique locations
        let locations = Set(memories.compactMap { $0.extractedLocation })
        if let location = locations.first {
            questions.append("Other memories at \(location)?")
        }

        return questions
    }

    private func saveRecentSearch(_ search: String) {
        if !recentSearches.contains(search) {
            recentSearches.insert(search, at: 0)
            if recentSearches.count > 5 {
                recentSearches.removeLast()
            }
            userPreferences.recentSearches = recentSearches
        }
    }

    func selectSuggestion(_ text: String) {
        query = text
        search()
    }

    func selectRecentSearch(_ searchText: String) {
        query = searchText
        search()
    }

    func removeRecentSearch(_ search: String) {
        recentSearches.removeAll { $0 == search }
        userPreferences.recentSearches = recentSearches
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        userPreferences.recentSearches = []
    }

    func newSearch() {
        query = ""
        searchState = .initial
        aiResponse = nil
    }

    func askFollowUp(_ question: String) {
        query = question
        search()
    }
}

// MARK: - Models
struct AIResponse {
    let mainAnswer: String
    let details: String?
    let highlight: String?
    let relatedMemories: [RelatedMemory]
    let followUpQuestions: [String]
}

struct RelatedMemory: Identifiable {
    let id: String
    let date: Date
    let content: String
    let tags: [MemoryTag]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct MemoryTag {
    let type: String
    let value: String

    var icon: String {
        switch type {
        case "person": return "person.fill"
        case "location": return "location.fill"
        default: return "calendar"
        }
    }
}

struct Suggestion: Identifiable {
    let id = UUID()
    let text: String
    let isHighlighted: Bool

    static let defaults = [
        Suggestion(text: "When is Mike's wedding?", isHighlighted: true),
        Suggestion(text: "What did I do with Mom last year?", isHighlighted: false),
        Suggestion(text: "Do I owe anyone money?", isHighlighted: false),
        Suggestion(text: "Summarize my work meetings this month", isHighlighted: true)
    ]
}

// MARK: - Main View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.searchState {
                case .initial:
                    InitialSearchContent(viewModel: viewModel)
                case .searching:
                    SearchingContent(query: viewModel.query)
                case .result:
                    if let response = viewModel.aiResponse {
                        SearchResultContent(
                            query: viewModel.query,
                            aiResponse: response,
                            onNewSearch: viewModel.newSearch,
                            onFollowUpClick: viewModel.askFollowUp
                        )
                    }
                case .empty:
                    EmptyResultContent(
                        query: viewModel.query,
                        onNewSearch: viewModel.newSearch
                    )
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Initial Content
struct InitialSearchContent: View {
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search Bar
                SearchBar(
                    query: $viewModel.query,
                    onSearch: viewModel.search
                )

                // Filter Button
                FilterButton()

                // Suggestions
                SuggestionsSection(
                    suggestions: viewModel.suggestions,
                    onSelect: viewModel.selectSuggestion
                )

                // Recent Searches
                if !viewModel.recentSearches.isEmpty {
                    RecentSearchesSection(
                        searches: viewModel.recentSearches,
                        onSelect: viewModel.selectRecentSearch,
                        onRemove: viewModel.removeRecentSearch,
                        onClear: viewModel.clearRecentSearches
                    )
                }

                Spacer(minLength: 100)
            }
            .padding(24)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var query: String
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.dmPrimary)

            TextField("Ask AI anything...", text: $query)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit(onSearch)

            Button(action: { /* Voice input */ }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.42, green: 0.22, blue: 0.83))
                    .padding(10)
                    .background(Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(24)
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    var body: some View {
        Button(action: { /* Open filter */ }) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.secondary)
                    Text("Filter search")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

// MARK: - Suggestions Section
struct SuggestionsSection: View {
    let suggestions: [Suggestion]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                Text("TRY ASKING...")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(suggestions) { suggestion in
                    SuggestionCard(
                        suggestion: suggestion,
                        onTap: { onSelect(suggestion.text) }
                    )
                }
            }
        }
    }
}

// MARK: - Suggestion Card
struct SuggestionCard: View {
    let suggestion: Suggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(suggestion.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(suggestion.isHighlighted ? Color(red: 0.42, green: 0.22, blue: 0.83) : .secondary)
                }
            }
            .padding(16)
            .frame(height: 110)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                suggestion.isHighlighted
                    ? Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.1)
                    : Color(.systemGray6)
            )
            .cornerRadius(24)
        }
    }
}

// MARK: - Recent Searches Section
struct RecentSearchesSection: View {
    let searches: [String]
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    Text("RECENT SEARCHES")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Clear") {
                    onClear()
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.dmPrimary)
            }

            VStack(spacing: 8) {
                ForEach(searches, id: \.self) { search in
                    RecentSearchItem(
                        search: search,
                        onTap: { onSelect(search) },
                        onRemove: { onRemove(search) }
                    )
                }
            }
        }
    }
}

// MARK: - Recent Search Item
struct RecentSearchItem: View {
    let search: String
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.gray)
                    Text(search)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Searching Content
struct SearchingContent: View {
    let query: String

    var body: some View {
        VStack(spacing: 0) {
            // Query Display
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.dmPrimary)
                Text(query)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(24)

            Spacer()

            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(red: 0.52, green: 0.33, blue: 0.94))

                Text("Searching your memories...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Search Result Content
struct SearchResultContent: View {
    let query: String
    let aiResponse: AIResponse
    let onNewSearch: () -> Void
    let onFollowUpClick: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Query Bar
                QueryBar(query: query, onNewSearch: onNewSearch)

                // AI Answer Card
                AIAnswerCard(aiResponse: aiResponse)

                // Related Memories
                if !aiResponse.relatedMemories.isEmpty {
                    RelatedMemoriesSection(memories: aiResponse.relatedMemories)
                }

                // Follow-up Questions
                if !aiResponse.followUpQuestions.isEmpty {
                    FollowUpSection(
                        questions: aiResponse.followUpQuestions,
                        onQuestionClick: onFollowUpClick
                    )
                }

                Spacer(minLength: 100)
            }
            .padding(24)
        }
    }
}

// MARK: - Query Bar
struct QueryBar: View {
    let query: String
    let onNewSearch: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.dmPrimary)
                Text(query)
                    .fontWeight(.semibold)
            }

            Spacer()

            Button("New search") {
                onNewSearch()
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.dmPrimary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - AI Answer Card
struct AIAnswerCard: View {
    let aiResponse: AIResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("AI Answer")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(Color(red: 0.52, green: 0.33, blue: 0.94))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.1))
                .cornerRadius(20)

                Spacer()

                Button(action: { /* Feedback */ }) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 12))
                        Text("Helpful")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
            }

            // Main Answer
            Text(aiResponse.mainAnswer)
                .font(.title2)
                .fontWeight(.bold)

            // Details
            if let details = aiResponse.details {
                Text(details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }

            // Highlight
            if let highlight = aiResponse.highlight {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text(highlight)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.dmPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.dmPrimary.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .overlay(
            HStack {
                Rectangle()
                    .fill(Color(red: 0.52, green: 0.33, blue: 0.94))
                    .frame(width: 4)
                Spacer()
            }
            .cornerRadius(24)
        )
        .shadow(color: Color(red: 0.52, green: 0.33, blue: 0.94).opacity(0.08), radius: 16, y: 8)
    }
}

// MARK: - Related Memories Section
struct RelatedMemoriesSection: View {
    let memories: [RelatedMemory]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .foregroundColor(.dmPrimary)
                Text("Related memories (\(memories.count))")
                    .font(.headline)
                    .fontWeight(.heavy)
            }

            ForEach(memories) { memory in
                NavigationLink(destination: MemoryDetailView(memoryId: memory.id)) {
                    RelatedMemoryCard(memory: memory)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Related Memory Card
struct RelatedMemoryCard: View {
    let memory: RelatedMemory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(memory.formattedDate)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text(memory.content)
                .font(.body)

            // Tags
            SearchFlowLayout(spacing: 8) {
                ForEach(memory.tags, id: \.value) { tag in
                    HStack(spacing: 6) {
                        Image(systemName: tag.icon)
                            .font(.system(size: 12))
                        Text(tag.value)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(24)
    }
}

// MARK: - Follow Up Section
struct FollowUpSection: View {
    let questions: [String]
    let onQuestionClick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 FOLLOW-UP QUESTIONS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundColor(.secondary)

            SearchFlowLayout(spacing: 12) {
                ForEach(questions, id: \.self) { question in
                    Button(action: { onQuestionClick(question) }) {
                        HStack(spacing: 8) {
                            Text(question)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.dmPrimary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.88, green: 0.91, blue: 0.99))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
}

// MARK: - Empty Result Content
struct EmptyResultContent: View {
    let query: String
    let onNewSearch: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            QueryBar(query: query, onNewSearch: onNewSearch)
                .padding(24)

            Spacer()

            VStack(spacing: 24) {
                Text("🔍")
                    .font(.system(size: 64))

                Text("No results found")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Try a different question or check your memories for related content.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}

// MARK: - Flow Layout
private struct SearchFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    SearchView()
}
