import SwiftUI

struct ReminderEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReminderEditViewModel

    let reminderId: String?
    let memoryId: String?
    let personId: String?

    init(reminderId: String? = nil, memoryId: String? = nil, personId: String? = nil) {
        self.reminderId = reminderId
        self.memoryId = memoryId
        self.personId = personId
        _viewModel = StateObject(wrappedValue: ReminderEditViewModel())
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title & Description
                Section {
                    TextField("What should I remind you about?", text: $viewModel.title)

                    TextField("Add more details...", text: $viewModel.body, axis: .vertical)
                        .lineLimit(3...5)
                }

                // Schedule
                Section("Schedule") {
                    DatePicker(
                        "Date",
                        selection: $viewModel.scheduledDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "Time",
                        selection: $viewModel.scheduledDate,
                        displayedComponents: .hourAndMinute
                    )

                    Picker("Repeat", selection: $viewModel.repeatType) {
                        ForEach(RepeatType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                // Quick Set
                Section("Quick Set") {
                    HStack(spacing: 12) {
                        QuickTimeButton(title: "In 1 hour") {
                            viewModel.setQuickTime(hours: 1)
                        }

                        QuickTimeButton(title: "Tomorrow") {
                            viewModel.setTomorrow()
                        }

                        QuickTimeButton(title: "Next week") {
                            viewModel.setNextWeek()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Link To
                Section("Link To") {
                    Picker("Person", selection: $viewModel.selectedPersonId) {
                        Text("None").tag(nil as String?)
                        ForEach(viewModel.availablePersons) { person in
                            Text(person.name).tag(person.id as String?)
                        }
                    }

                    if let memoryPreview = viewModel.linkedMemoryPreview {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text("Linked Memory")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(memoryPreview)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle(reminderId != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.saveSuccess {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .task {
                await viewModel.initialize(
                    reminderId: reminderId,
                    memoryId: memoryId,
                    personId: personId
                )
            }
        }
    }
}

private struct QuickTimeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

@MainActor
class ReminderEditViewModel: ObservableObject {
    @Published var title = ""
    @Published var body = ""
    @Published var scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
    @Published var repeatType = RepeatType.none
    @Published var selectedPersonId: String?
    @Published var linkedMemoryPreview: String?
    @Published var availablePersons: [Person] = []
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var error: String?

    private var existingReminderId: String?
    private var linkedMemoryId: String?

    private let saveReminderUseCase = DIContainer.shared.saveReminderUseCase
    private let updateReminderUseCase = DIContainer.shared.updateReminderUseCase
    private let getMemoryUseCase = DIContainer.shared.getMemoryUseCase
    private let getPersonUseCase = DIContainer.shared.getPersonUseCase
    private let getAllPersonsUseCase = DIContainer.shared.getAllPersonsUseCase
    private let notificationService = NotificationService.shared

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func initialize(reminderId: String?, memoryId: String?, personId: String?) async {
        // Load available persons
        do {
            availablePersons = try await getAllPersonsUseCase.execute()
        } catch {
            // Ignore
        }

        // Load existing reminder if editing
        if let reminderId = reminderId {
            existingReminderId = reminderId
            // TODO: Load existing reminder
        }

        // Load linked memory if provided
        if let memoryId = memoryId {
            linkedMemoryId = memoryId
            do {
                if let memory = try await getMemoryUseCase.execute(id: memoryId) {
                    linkedMemoryPreview = String(memory.content.prefix(100))
                }
            } catch {
                // Ignore
            }
        }

        // Load linked person if provided
        if let personId = personId {
            selectedPersonId = personId
        }
    }

    func setQuickTime(hours: Int) {
        scheduledDate = Date().addingTimeInterval(Double(hours * 3600))
    }

    func setTomorrow() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        if let date = Calendar.current.date(from: components) {
            scheduledDate = date
        }
    }

    func setNextWeek() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 7
        components.hour = 9
        components.minute = 0
        if let date = Calendar.current.date(from: components) {
            scheduledDate = date
        }
    }

    func save() async {
        guard isValid else { return }

        isSaving = true
        error = nil

        let reminder = Reminder(
            id: existingReminderId ?? UUID().uuidString,
            memoryId: linkedMemoryId,
            personId: selectedPersonId,
            title: title,
            body: body,
            scheduledAt: scheduledDate,
            repeatType: repeatType,
            isActive: true,
            isAutoGenerated: false
        )

        do {
            if existingReminderId != nil {
                _ = try await updateReminderUseCase.execute(reminder)
            } else {
                _ = try await saveReminderUseCase.execute(reminder)
            }

            // Schedule notification
            await notificationService.scheduleReminder(reminder)

            saveSuccess = true
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }
}

#Preview {
    ReminderEditView()
}
