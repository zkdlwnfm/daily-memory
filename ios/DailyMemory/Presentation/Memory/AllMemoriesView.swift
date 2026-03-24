import SwiftUI

// MARK: - ViewModel
@MainActor
class AllMemoriesViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var isLoading = true
    @Published var error: String?

    private let getRecentMemoriesUseCase: GetRecentMemoriesUseCase
    private let searchMemoriesUseCase: SearchMemoriesUseCase

    init(
        getRecentMemoriesUseCase: GetRecentMemoriesUseCase = DIContainer.shared.getRecentMemoriesUseCase,
        searchMemoriesUseCase: SearchMemoriesUseCase = DIContainer.shared.searchMemoriesUseCase
    ) {
        self.getRecentMemoriesUseCase = getRecentMemoriesUseCase
        self.searchMemoriesUseCase = searchMemoriesUseCase
    }

    func loadMemories() async {
        isLoading = true
        do {
            memories = try await getRecentMemoriesUseCase.execute(limit: 100)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func search(query: String) async {
        guard !query.isEmpty else {
            await loadMemories()
            return
        }

        isLoading = true
        do {
            memories = try await searchMemoriesUseCase.byContent(query: query)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - View
struct AllMemoriesView: View {
    @StateObject private var viewModel = AllMemoriesViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search memories...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await viewModel.search(query: searchText) }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await viewModel.loadMemories() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.memories.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No memories found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.memories) { memory in
                            NavigationLink(destination: MemoryDetailView(memoryId: memory.id)) {
                                MemoryListCard(memory: memory)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("All Memories")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadMemories()
        }
        .refreshable {
            await viewModel.loadMemories()
        }
    }
}

// MARK: - Memory List Card
struct MemoryListCard: View {
    let memory: Memory

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: memory.recordedAt)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: memory.recordedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formattedDate.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.dmPrimary.opacity(0.7))
                    .tracking(1)

                Spacer()

                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(memory.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)

            HStack(spacing: 8) {
                if !memory.extractedPersons.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.caption2)
                        Text("\(memory.extractedPersons.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                if memory.extractedLocation != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                if !memory.photos.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.caption2)
                        Text("\(memory.photos.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }
}

#Preview {
    NavigationStack {
        AllMemoriesView()
    }
}
