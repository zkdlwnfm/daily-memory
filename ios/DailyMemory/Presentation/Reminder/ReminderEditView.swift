import SwiftUI
import CoreLocation

struct ReminderEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReminderEditViewModel

    let reminderId: String?
    let memoryId: String?
    let personId: String?

    @State private var showLocationPicker = false

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

                // Location-based Reminder
                Section("Location") {
                    Toggle("Location-based", isOn: $viewModel.isLocationBased)

                    if viewModel.isLocationBased {
                        if let location = viewModel.selectedLocation {
                            Button {
                                showLocationPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading) {
                                        Text(location.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        if let address = location.address {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        HStack {
                                            Image(systemName: location.triggerType.icon)
                                                .font(.caption)
                                            Text(location.triggerType.displayName)
                                                .font(.caption)
                                            Text("within \(Int(location.radius))m")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Button {
                                showLocationPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.accentColor)
                                    Text("Select Location")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
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
            .sheet(isPresented: $showLocationPicker) {
                if #available(iOS 17.0, *) {
                    LocationPickerView(initialLocation: viewModel.selectedLocation) { location in
                        viewModel.selectedLocation = location
                    }
                } else {
                    Text("Location picker requires iOS 17+")
                }
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

    // Location-based reminder
    @Published var isLocationBased = false
    @Published var selectedLocation: SelectedLocation?

    private var existingReminderId: String?
    private var linkedMemoryId: String?

    private let saveReminderUseCase = DIContainer.shared.saveReminderUseCase
    private let updateReminderUseCase = DIContainer.shared.updateReminderUseCase
    private let getMemoryUseCase = DIContainer.shared.getMemoryUseCase
    private let getPersonUseCase = DIContainer.shared.getPersonUseCase
    private let getAllPersonsUseCase = DIContainer.shared.getAllPersonsUseCase
    private let notificationService = NotificationService.shared
    private let geofenceService = GeofenceService.shared

    var isValid: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        if isLocationBased {
            return hasTitle && selectedLocation != nil
        }
        return hasTitle
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
            do {
                let reminderRepo = DIContainer.shared.reminderRepository
                if let reminder = try await reminderRepo.getById(reminderId) {
                    title = reminder.title
                    body = reminder.body
                    scheduledDate = reminder.scheduledAt
                    repeatType = reminder.repeatType

                    // Load location data
                    if reminder.isLocationBased {
                        isLocationBased = true
                        if let lat = reminder.latitude,
                           let lng = reminder.longitude {
                            selectedLocation = SelectedLocation(
                                name: reminder.locationName ?? "Selected Location",
                                address: nil,
                                coordinate: .init(latitude: lat, longitude: lng),
                                radius: reminder.radius ?? 100,
                                triggerType: reminder.locationTriggerType ?? .enter
                            )
                        }
                    }

                    linkedMemoryId = reminder.memoryId
                    selectedPersonId = reminder.personId
                }
            } catch {
                // Ignore
            }
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

        var reminder = Reminder(
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

        // Add location data if location-based
        if isLocationBased, let location = selectedLocation {
            reminder.latitude = location.coordinate.latitude
            reminder.longitude = location.coordinate.longitude
            reminder.radius = location.radius
            reminder.locationTriggerType = location.triggerType
            reminder.locationName = location.name
        }

        do {
            if existingReminderId != nil {
                _ = try await updateReminderUseCase.execute(reminder)
            } else {
                _ = try await saveReminderUseCase.execute(reminder)
            }

            // Schedule notification or geofence
            if reminder.isLocationBased {
                // Start geofence monitoring
                if geofenceService.hasGeofenceAuthorization {
                    _ = geofenceService.startMonitoring(reminder: reminder)
                } else {
                    geofenceService.requestAlwaysAuthorization()
                }
            } else {
                // Schedule time-based notification
                await notificationService.scheduleReminder(reminder)
            }

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
