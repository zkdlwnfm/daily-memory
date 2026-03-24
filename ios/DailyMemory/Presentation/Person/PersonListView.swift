import SwiftUI

// MARK: - ViewModel
@MainActor
class PeopleViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var filteredPeople: [Person] = []
    @Published var searchQuery: String = ""
    @Published var sortOrder: SortOrder = .recent
    @Published var isLoading: Bool = true
    @Published var error: String?

    private let getAllPersonsUseCase: GetAllPersonsUseCase
    private let getPersonUseCase: GetPersonUseCase
    private let savePersonUseCase: SavePersonUseCase
    private let updatePersonUseCase: UpdatePersonUseCase
    private let deletePersonUseCase: DeletePersonUseCase
    private let searchMemoriesUseCase: SearchMemoriesUseCase

    enum SortOrder: String, CaseIterable {
        case recent = "Recent"
        case alphabetical = "A-Z"
        case frequent = "Frequent"
    }

    init(
        getAllPersonsUseCase: GetAllPersonsUseCase = DIContainer.shared.getAllPersonsUseCase,
        getPersonUseCase: GetPersonUseCase = DIContainer.shared.getPersonUseCase,
        savePersonUseCase: SavePersonUseCase = DIContainer.shared.savePersonUseCase,
        updatePersonUseCase: UpdatePersonUseCase = DIContainer.shared.updatePersonUseCase,
        deletePersonUseCase: DeletePersonUseCase = DIContainer.shared.deletePersonUseCase,
        searchMemoriesUseCase: SearchMemoriesUseCase = DIContainer.shared.searchMemoriesUseCase
    ) {
        self.getAllPersonsUseCase = getAllPersonsUseCase
        self.getPersonUseCase = getPersonUseCase
        self.savePersonUseCase = savePersonUseCase
        self.updatePersonUseCase = updatePersonUseCase
        self.deletePersonUseCase = deletePersonUseCase
        self.searchMemoriesUseCase = searchMemoriesUseCase

        Task {
            await loadPeople()
        }
    }

    func loadPeople() async {
        isLoading = true

        do {
            let persons = try await getAllPersonsUseCase.execute()
            people = persons
            filteredPeople = sortPeople(persons)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        let filtered = query.isEmpty ? people : people.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            ($0.nickname?.localizedCaseInsensitiveContains(query) ?? false)
        }
        filteredPeople = sortPeople(filtered)
    }

    func updateSortOrder(_ order: SortOrder) {
        sortOrder = order
        filteredPeople = sortPeople(filteredPeople)
    }

    private func sortPeople(_ people: [Person]) -> [Person] {
        switch sortOrder {
        case .recent:
            return people.sorted { ($0.lastMeetingDate ?? .distantPast) > ($1.lastMeetingDate ?? .distantPast) }
        case .alphabetical:
            return people.sorted { $0.name < $1.name }
        case .frequent:
            return people.sorted { $0.meetingCount > $1.meetingCount }
        }
    }

    func getPerson(by id: String) -> Person? {
        people.first { $0.id == id }
    }

    func getPersonAsync(by id: String) async -> Person? {
        do {
            return try await getPersonUseCase.execute(id: id)
        } catch {
            return nil
        }
    }

    func savePerson(_ person: Person) async {
        do {
            try await savePersonUseCase.execute(person)
            await loadPeople()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updatePerson(_ person: Person) async {
        do {
            try await updatePersonUseCase.execute(person)
            await loadPeople()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deletePerson(_ personId: String) async {
        do {
            try await deletePersonUseCase.execute(personId: personId)
            await loadPeople()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func getMemoryCount(for personId: String) async -> Int {
        do {
            let memories = try await searchMemoriesUseCase.byPerson(personId: personId)
            return memories.count
        } catch {
            return 0
        }
    }

    func refresh() async {
        await loadPeople()
    }

    func clearError() {
        error = nil
    }
}

// MARK: - Main View
struct PersonListView: View {
    @StateObject private var viewModel = PeopleViewModel()
    @State private var searchText = ""
    @State private var selectedPerson: Person?
    @State private var showAddPerson = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Search Bar
                    searchBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Sort Tabs
                    sortTabs
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // People List
                    if viewModel.filteredPeople.isEmpty && !viewModel.isLoading {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        peopleList
                            .padding(.top, 16)
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedPerson) { person in
                NavigationStack {
                    PersonDetailView(person: person, viewModel: viewModel)
                }
            }
        }
        .onChange(of: searchText) { newValue in
            viewModel.updateSearchQuery(newValue)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.dmPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("People")
                        .font(.title)
                        .fontWeight(.heavy)

                    Text("Keep track of your meaningful connections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: { showAddPerson = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(.white)
                .background(Color.dmPrimary)
                .cornerRadius(12)
            }
            .sheet(isPresented: $showAddPerson) {
                PersonEditView(personId: nil)
                    .onDisappear {
                        Task { await viewModel.loadPeople() }
                    }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search people...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Sort Tabs
    private var sortTabs: some View {
        HStack(spacing: 8) {
            ForEach(PeopleViewModel.SortOrder.allCases, id: \.self) { order in
                SortChip(
                    title: order.rawValue,
                    isSelected: viewModel.sortOrder == order,
                    action: { viewModel.updateSortOrder(order) }
                )
            }
            Spacer()
        }
    }

    // MARK: - People List
    private var peopleList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredPeople) { person in
                PersonCard(person: person)
                    .onTapGesture {
                        selectedPerson = person
                    }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Text("👥")
                .font(.system(size: 64))

            VStack(spacing: 8) {
                Text("No people yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Record memories and AI will automatically find people, or add them manually.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { showAddPerson = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Person")
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(Color.dmPrimary)
                .cornerRadius(16)
            }
        }
        .padding(32)
    }
}

// MARK: - Sort Chip
struct SortChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .secondary)
                .background(isSelected ? Color.dmPrimary : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

// MARK: - Person Card
struct PersonCard: View {
    let person: Person

    private var daysAgo: Int {
        guard let lastDate = person.lastMeetingDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }

    private var hasNoContactWarning: Bool {
        daysAgo > 30
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            PersonAvatar(
                name: person.name,
                relationship: person.relationship
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(person.name)
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.4))
                }

                Text(buildSubtitle())
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Tags
                HStack(spacing: 8) {
                    TagChip(
                        icon: "note.text",
                        text: "\(person.meetingCount) memories",
                        color: .dmPrimary
                    )

                    if hasNoContactWarning {
                        TagChip(
                            icon: "exclamationmark.triangle.fill",
                            text: "No contact for \(daysAgo) days",
                            color: .red,
                            backgroundColor: Color.red.opacity(0.1)
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .overlay(
            Group {
                if hasNoContactWarning {
                    HStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 4)
                        Spacer()
                    }
                }
            }
            .cornerRadius(24)
        )
    }

    private func buildSubtitle() -> String {
        var parts: [String] = [person.relationship.displayName]

        if let lastDate = person.lastMeetingDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            parts.append("Last seen \(formatter.string(from: lastDate))")
        }

        return parts.joined(separator: " · ")
    }
}

// MARK: - Person Avatar
struct PersonAvatar: View {
    let name: String
    let relationship: Relationship
    var size: CGFloat = 56

    private var backgroundColor: Color {
        switch relationship {
        case .family: return Color(red: 0.91, green: 0.87, blue: 1.0)
        case .friend: return Color(red: 0.88, green: 0.88, blue: 1.0)
        case .colleague: return Color(red: 0.88, green: 0.91, blue: 0.99)
        default: return Color(red: 0.86, green: 0.89, blue: 0.97)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let icon: String
    let text: String
    let color: Color
    var backgroundColor: Color? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor ?? color.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    PersonListView()
}
