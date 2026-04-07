import SwiftUI

// MARK: - ViewModel
@MainActor
final class MemoryDetailViewModel: ObservableObject {
    @Published var memory: Memory?
    @Published var linkedPersons: [Person] = []
    @Published var isLoading = true
    @Published var isDeleting = false
    @Published var error: String?
    @Published var deleteSuccess = false
    @Published var showDeleteDialog = false

    private let getMemoryUseCase: GetMemoryUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    private let updateMemoryUseCase: UpdateMemoryUseCase
    private let getPersonUseCase: GetPersonUseCase

    init(
        getMemoryUseCase: GetMemoryUseCase = DIContainer.shared.getMemoryUseCase,
        deleteMemoryUseCase: DeleteMemoryUseCase = DIContainer.shared.deleteMemoryUseCase,
        updateMemoryUseCase: UpdateMemoryUseCase = DIContainer.shared.updateMemoryUseCase,
        getPersonUseCase: GetPersonUseCase = DIContainer.shared.getPersonUseCase
    ) {
        self.getMemoryUseCase = getMemoryUseCase
        self.deleteMemoryUseCase = deleteMemoryUseCase
        self.updateMemoryUseCase = updateMemoryUseCase
        self.getPersonUseCase = getPersonUseCase
    }

    func loadMemory(id: String) async {
        isLoading = true
        error = nil

        do {
            if let memory = try await getMemoryUseCase.execute(id: id) {
                self.memory = memory

                // Load linked persons
                var persons: [Person] = []
                for personId in memory.personIds {
                    if let person = try await getPersonUseCase.execute(id: personId) {
                        persons.append(person)
                    }
                }
                linkedPersons = persons
            } else {
                error = "Memory not found"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func deleteMemory() async {
        guard let memory = memory else { return }

        isDeleting = true
        showDeleteDialog = false

        do {
            try await deleteMemoryUseCase.execute(memoryId: memory.id)
            deleteSuccess = true
            // Notify Home to refresh
            NotificationCenter.default.post(name: .memoryChanged, object: nil)
        } catch {
            self.error = error.localizedDescription
        }

        isDeleting = false
    }

    func updateCategory(_ category: Category) async {
        guard var memory = memory else { return }
        memory.category = category
        memory.updatedAt = Date()

        do {
            _ = try await updateMemoryUseCase.execute(memory)
            self.memory = memory
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateImportance(_ importance: Int) async {
        guard var memory = memory else { return }
        memory.importance = max(1, min(5, importance))
        memory.updatedAt = Date()

        do {
            _ = try await updateMemoryUseCase.execute(memory)
            self.memory = memory
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleLock() async {
        guard var memory = memory else { return }
        memory.isLocked.toggle()
        memory.updatedAt = Date()

        do {
            _ = try await updateMemoryUseCase.execute(memory)
            self.memory = memory
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - View
struct MemoryDetailView: View {
    let memoryId: String
    @StateObject private var viewModel = MemoryDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showMenu = false
    @State private var showEditSheet = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading || viewModel.isDeleting {
                ProgressView()
            } else if let memory = viewModel.memory {
                MemoryDetailContent(
                    memory: memory,
                    linkedPersons: viewModel.linkedPersons,
                    onCategoryChange: { category in
                        Task { await viewModel.updateCategory(category) }
                    },
                    onImportanceChange: { importance in
                        Task { await viewModel.updateImportance(importance) }
                    }
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Memory Not Found")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("The memory you're looking for doesn't exist.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    if let memory = viewModel.memory {
                        Button {
                            Task { await viewModel.toggleLock() }
                        } label: {
                            Image(systemName: memory.isLocked ? "lock.fill" : "lock.open")
                                .foregroundColor(memory.isLocked ? .dmPrimary : .secondary)
                        }

                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }

                        Menu {
                            Button(role: .destructive) {
                                viewModel.showDeleteDialog = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
        }
        .alert("Delete Memory", isPresented: $viewModel.showDeleteDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteMemory() }
            }
        } message: {
            Text("Are you sure you want to delete this memory? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.deleteSuccess) { success in
            if success {
                dismiss()
            }
        }
        .task {
            await viewModel.loadMemory(id: memoryId)
        }
        .sheet(isPresented: $showEditSheet) {
            MemoryEditView(memoryId: memoryId)
                .onDisappear {
                    Task { await viewModel.loadMemory(id: memoryId) }
                }
        }
    }
}

// MARK: - Content View
struct MemoryDetailContent: View {
    let memory: Memory
    let linkedPersons: [Person]
    let onCategoryChange: (Category) -> Void
    let onImportanceChange: (Int) -> Void

    @State private var showPhotoGallery = false
    @State private var selectedPhotoIndex = 0

    private let photoService = PhotoService.shared

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date Header
                dateHeader

                // Main Content Card
                contentCard

                // Photos Section
                if !memory.photos.isEmpty {
                    photosSection
                }

                // Extracted Info
                if hasExtractedInfo {
                    extractedInfoSection
                }

                // Linked People
                if !linkedPersons.isEmpty {
                    linkedPeopleSection
                }

                // Tags
                if !memory.extractedTags.isEmpty {
                    tagsSection
                }

                // Category & Importance
                categoryAndImportanceSection

                // Metadata
                metadataSection
            }
            .padding(24)
        }
    }

    // MARK: - Date Header
    private var dateHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.dmPrimary)

                Text(dateFormatter.string(from: memory.recordedAt))
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text(timeFormatter.string(from: memory.recordedAt))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Content Card
    private var contentCard: some View {
        VStack(alignment: .leading) {
            Text(memory.content)
                .font(.body)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos (\(memory.photos.count))")
                .font(.subheadline)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(memory.photos.enumerated()), id: \.element.id) { index, photo in
                        Button {
                            selectedPhotoIndex = index
                            showPhotoGallery = true
                        } label: {
                            if let thumbnail = photoService.loadThumbnail(photoId: photo.id) {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .cornerRadius(16)
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 120, height: 120)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .foregroundColor(.secondary)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPhotoGallery) {
            PhotoGalleryView(
                photoIds: memory.photos.map { $0.id },
                initialIndex: selectedPhotoIndex
            )
        }
    }

    // MARK: - Extracted Info
    private var hasExtractedInfo: Bool {
        memory.extractedLocation != nil ||
        memory.extractedAmount != nil ||
        !memory.extractedPersons.isEmpty
    }

    private var extractedInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Extracted")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.dmPrimary)

            FlowLayout(spacing: 8) {
                if let location = memory.extractedLocation {
                    InfoChip(
                        icon: "location.fill",
                        text: location,
                        backgroundColor: Color.green.opacity(0.15),
                        foregroundColor: .green
                    )
                }

                if let amount = memory.extractedAmount {
                    InfoChip(
                        icon: "dollarsign.circle.fill",
                        text: String(format: "$%.2f", amount),
                        backgroundColor: Color.orange.opacity(0.15),
                        foregroundColor: .orange
                    )
                }

                ForEach(memory.extractedPersons, id: \.self) { person in
                    InfoChip(
                        icon: "person.fill",
                        text: person,
                        backgroundColor: Color.blue.opacity(0.15),
                        foregroundColor: .blue
                    )
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.95, green: 0.95, blue: 1.0))
        .cornerRadius(20)
    }

    // MARK: - Linked People
    private var linkedPeopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.dmPrimary)
                Text("Linked People")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(linkedPersons) { person in
                        PersonChipView(person: person)
                    }
                }
            }
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.dmPrimary)
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            FlowLayout(spacing: 8) {
                ForEach(memory.extractedTags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Category & Importance
    private var categoryAndImportanceSection: some View {
        VStack(spacing: 16) {
            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Button {
                            onCategoryChange(category)
                        } label: {
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    category == memory.category
                                        ? Color.dmPrimary
                                        : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    category == memory.category
                                        ? .white
                                        : .secondary
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Importance
            VStack(alignment: .leading, spacing: 8) {
                Text("Importance")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            onImportanceChange(star)
                        } label: {
                            Image(systemName: star <= memory.importance ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundColor(star <= memory.importance ? .yellow : Color(.systemGray4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Metadata
    private var metadataSection: some View {
        let detailFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy h:mm a"
            return formatter
        }()

        return VStack(spacing: 8) {
            Text("Details")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            MetadataRow(label: "Created", value: detailFormatter.string(from: memory.createdAt))
            MetadataRow(label: "Updated", value: detailFormatter.string(from: memory.updatedAt))

            if let lat = memory.recordedLatitude, let lng = memory.recordedLongitude {
                MetadataRow(label: "Location", value: String(format: "%.4f, %.4f", lat, lng))
            }

            MetadataRow(label: "Sync Status", value: memory.syncStatus.rawValue.capitalized)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

// MARK: - Supporting Views
struct InfoChip: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct PersonChipView: View {
    let person: Person

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)

                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(person.relationship.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        MemoryDetailView(memoryId: "preview")
    }
}
