import SwiftUI

// MARK: - ViewModel
@MainActor
class MemoryEditViewModel: ObservableObject {
    @Published var content = ""
    @Published var category: Category = .general
    @Published var importance = 3
    @Published var isLocked = false
    @Published var excludeFromAI = false
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var error: String?

    private var memory: Memory?
    private let getMemoryUseCase: GetMemoryUseCase
    private let updateMemoryUseCase: UpdateMemoryUseCase

    init(
        getMemoryUseCase: GetMemoryUseCase = DIContainer.shared.getMemoryUseCase,
        updateMemoryUseCase: UpdateMemoryUseCase = DIContainer.shared.updateMemoryUseCase
    ) {
        self.getMemoryUseCase = getMemoryUseCase
        self.updateMemoryUseCase = updateMemoryUseCase
    }

    func loadMemory(id: String) async {
        isLoading = true
        do {
            if let memory = try await getMemoryUseCase.execute(id: id) {
                self.memory = memory
                self.content = memory.content
                self.category = memory.category
                self.importance = memory.importance
                self.isLocked = memory.isLocked
                self.excludeFromAI = memory.excludeFromAI
            } else {
                error = "Memory not found"
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func save() async {
        guard var memory = memory else { return }
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Content cannot be empty"
            return
        }

        isSaving = true

        memory.content = content
        memory.category = category
        memory.importance = importance
        memory.isLocked = isLocked
        memory.excludeFromAI = excludeFromAI
        memory.updatedAt = Date()

        do {
            _ = try await updateMemoryUseCase.execute(memory)
            saveSuccess = true
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - View
struct MemoryEditView: View {
    let memoryId: String
    @StateObject private var viewModel = MemoryEditViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Content
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Content")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                TextEditor(text: $viewModel.content)
                                    .frame(minHeight: 150)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                            }

                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(Category.allCases, id: \.self) { category in
                                        Button {
                                            viewModel.category = category
                                        } label: {
                                            Text(category.displayName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    category == viewModel.category
                                                        ? Color.dmPrimary
                                                        : Color(.systemGray6)
                                                )
                                                .foregroundColor(
                                                    category == viewModel.category
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
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            viewModel.importance = star
                                        } label: {
                                            Image(systemName: star <= viewModel.importance ? "star.fill" : "star")
                                                .font(.system(size: 28))
                                                .foregroundColor(star <= viewModel.importance ? .yellow : Color(.systemGray4))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Privacy
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Privacy")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                Toggle("Lock this memory", isOn: $viewModel.isLocked)
                                Toggle("Exclude from AI analysis", isOn: $viewModel.excludeFromAI)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)

                            Spacer(minLength: 32)
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.content.isEmpty || viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.saveSuccess) { success in
                if success {
                    dismiss()
                }
            }
            .task {
                await viewModel.loadMemory(id: memoryId)
            }
        }
    }
}

#Preview {
    MemoryEditView(memoryId: "preview")
}
