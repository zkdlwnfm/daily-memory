import SwiftUI

// MARK: - ViewModel
@MainActor
final class PersonEditViewModel: ObservableObject {
    @Published var isEditing = false
    @Published var personId: String?
    @Published var name = ""
    @Published var nickname = ""
    @Published var relationship: Relationship = .friend
    @Published var phone = ""
    @Published var email = ""
    @Published var memo = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var error: String?
    @Published var nameError: String?

    private let getPersonUseCase: GetPersonUseCase
    private let savePersonUseCase: SavePersonUseCase
    private let updatePersonUseCase: UpdatePersonUseCase

    init(
        getPersonUseCase: GetPersonUseCase = DIContainer.shared.getPersonUseCase,
        savePersonUseCase: SavePersonUseCase = DIContainer.shared.savePersonUseCase,
        updatePersonUseCase: UpdatePersonUseCase = DIContainer.shared.updatePersonUseCase
    ) {
        self.getPersonUseCase = getPersonUseCase
        self.savePersonUseCase = savePersonUseCase
        self.updatePersonUseCase = updatePersonUseCase
    }

    func loadPerson(id: String?) async {
        guard let id = id, !id.isEmpty else {
            isEditing = false
            isLoading = false
            return
        }

        isLoading = true
        isEditing = true
        personId = id

        do {
            if let person = try await getPersonUseCase.execute(id: id) {
                name = person.name
                nickname = person.nickname ?? ""
                relationship = person.relationship
                phone = person.phone ?? ""
                email = person.email ?? ""
                memo = person.memo ?? ""
            } else {
                error = "Person not found"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func updateName(_ value: String) {
        name = value
        nameError = value.trimmingCharacters(in: .whitespaces).isEmpty ? "Name is required" : nil
    }

    func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            nameError = "Name is required"
            return
        }

        isSaving = true

        let person = Person(
            id: personId ?? UUID().uuidString,
            name: trimmedName,
            nickname: nickname.isEmpty ? nil : nickname,
            relationship: relationship,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            memo: memo.isEmpty ? nil : memo,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            if isEditing {
                _ = try await updatePersonUseCase.execute(person)
            } else {
                _ = try await savePersonUseCase.execute(person)
            }
            saveSuccess = true
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - View
struct PersonEditView: View {
    let personId: String?
    @StateObject private var viewModel = PersonEditViewModel()
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
                        VStack(spacing: 24) {
                            // Profile Photo
                            profilePhotoSection

                            // Form Fields
                            VStack(spacing: 20) {
                                // Name
                                formSection(title: "Name *") {
                                    TextField("Enter name", text: Binding(
                                        get: { viewModel.name },
                                        set: { viewModel.updateName($0) }
                                    ))
                                    .textInputAutocapitalization(.words)

                                    if let error = viewModel.nameError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                // Nickname
                                formSection(title: "Nickname") {
                                    TextField("Enter nickname (optional)", text: $viewModel.nickname)
                                        .textInputAutocapitalization(.words)
                                }

                                // Relationship
                                formSection(title: "Relationship") {
                                    relationshipPicker
                                }

                                // Contact Information
                                formSection(title: "Contact Information") {
                                    VStack(spacing: 12) {
                                        TextField("Phone number", text: $viewModel.phone)
                                            .keyboardType(.phonePad)
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)

                                        TextField("Email address", text: $viewModel.email)
                                            .keyboardType(.emailAddress)
                                            .textInputAutocapitalization(.never)
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                    }
                                }

                                // Memo
                                formSection(title: "Memo") {
                                    TextEditor(text: $viewModel.memo)
                                        .frame(minHeight: 100)
                                        .padding(8)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .overlay(
                                            Group {
                                                if viewModel.memo.isEmpty {
                                                    Text("Notes about this person...")
                                                        .foregroundColor(.secondary)
                                                        .padding(.leading, 12)
                                                        .padding(.top, 16)
                                                }
                                            },
                                            alignment: .topLeading
                                        )
                                }
                            }

                            // Save Button
                            Button {
                                Task { await viewModel.save() }
                            } label: {
                                HStack {
                                    if viewModel.isSaving {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(viewModel.isEditing ? "Save Changes" : "Add Person")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.name.isEmpty ? Color.gray : Color.dmPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .disabled(viewModel.name.isEmpty || viewModel.isSaving)

                            Spacer(minLength: 32)
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Person" : "Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                await viewModel.loadPerson(id: personId)
            }
        }
    }

    // MARK: - Profile Photo Section
    private var profilePhotoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }

            Button {
                // TODO: Pick image
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dmPrimary)
                        .frame(width: 32, height: 32)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Form Section
    @ViewBuilder
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            content()
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Relationship Picker
    private var relationshipPicker: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(Relationship.allCases, id: \.self) { relationship in
                Button {
                    viewModel.relationship = relationship
                } label: {
                    HStack(spacing: 4) {
                        Text(relationshipEmoji(relationship))
                            .font(.caption)
                        Text(relationship.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        viewModel.relationship == relationship
                            ? Color.dmPrimary
                            : Color(.systemGray6)
                    )
                    .foregroundColor(
                        viewModel.relationship == relationship
                            ? .white
                            : .secondary
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func relationshipEmoji(_ relationship: Relationship) -> String {
        switch relationship {
        case .family: return "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"
        case .friend: return "\u{1F46B}"
        case .colleague: return "\u{1F4BC}"
        case .business: return "\u{1F91D}"
        case .acquaintance: return "\u{1F44B}"
        case .other: return "\u{1F464}"
        }
    }
}

#Preview {
    PersonEditView(personId: nil)
}
