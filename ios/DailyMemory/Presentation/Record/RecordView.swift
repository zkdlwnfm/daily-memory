import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecordViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                switch viewModel.recordState {
                case .voiceIdle:
                    VoiceIdleView(
                        onStartRecording: { viewModel.startRecording() }
                    )

                case .voiceRecording:
                    VoiceRecordingView(
                        elapsedTime: viewModel.recordingTime,
                        transcription: viewModel.transcription,
                        onStopRecording: { viewModel.stopRecording() }
                    )

                case .textMode:
                    TextModeView(
                        text: $viewModel.textContent,
                        onAnalyze: { viewModel.analyzeWithAI() },
                        onSaveWithoutAnalysis: {
                            viewModel.saveWithoutAnalysis()
                            dismiss()
                        }
                    )

                case .aiProcessing:
                    AIProcessingView()

                case .aiResult:
                    if let result = viewModel.aiResult {
                        AIResultView(
                            result: result,
                            onCategorySelect: { viewModel.selectCategory($0) },
                            onPersonRemove: { viewModel.togglePerson($0) }
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    switch viewModel.recordState {
                    case .voiceIdle, .voiceRecording:
                        Button("Type instead") {
                            viewModel.toggleMode()
                        }
                        .foregroundColor(.dmPrimary)

                    case .textMode:
                        Button {
                            viewModel.toggleMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                Text("Voice input")
                            }
                        }
                        .foregroundColor(.dmPrimary)

                    case .aiResult:
                        Button("Save") {
                            viewModel.saveMemory()
                            dismiss()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.dmPrimary)
                        .cornerRadius(20)

                    case .aiProcessing:
                        EmptyView()
                    }
                }
            }
        }
    }
}

// MARK: - Voice Idle View
struct VoiceIdleView: View {
    let onStartRecording: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mic Button
            Button(action: onStartRecording) {
                Circle()
                    .fill(Color.dmPrimary)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .dmPrimary.opacity(0.3), radius: 20, y: 10)
            }

            Spacer().frame(height: 24)

            Text("Tap to record")
                .font(.title2)
                .fontWeight(.bold)

            Text("Capture a moment from your day")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            // Tip Card
            TipCard(
                text: "Just speak naturally. AI will extract people, places, and events.",
                subtext: "Your recording is private and encrypted."
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Voice Recording View
struct VoiceRecordingView: View {
    let elapsedTime: String
    let transcription: String
    let onStopRecording: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            // Timer Circle
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 140, height: 140)

                Text(elapsedTime)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer().frame(height: 24)

            // Waveform
            WaveformView()

            Spacer().frame(height: 16)

            Text("Recording...")
                .font(.headline)
                .foregroundColor(.red)

            Text("DailyMemory is listening")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer().frame(height: 24)

            // Transcription
            if !transcription.isEmpty {
                TranscriptionCard(text: transcription)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Stop Button
            Button(action: onStopRecording) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                    }
            }

            Text("TAP TO STOP")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .padding(.top, 8)

            Spacer().frame(height: 24)

            TipCard(
                text: "Speak naturally. DailyMemory automatically organizes names, dates, and amounts mentioned.",
                prefix: "Tip:"
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                let height: CGFloat = [16, 24, 32, 40, 32, 24, 16][index]
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 6, height: height)
            }
        }
    }
}

// MARK: - Transcription Card
struct TranscriptionCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("❝")
                .font(.title)
                .foregroundColor(.dmPrimary.opacity(0.5))

            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.body)

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("LIVE TRANSCRIPTION")
                        .font(.caption2)
                        .tracking(1)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - Tip Card
struct TipCard: View {
    let text: String
    var subtext: String? = nil
    var prefix: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "FEF3C7"))
                .frame(width: 40, height: 40)
                .overlay {
                    Text("💡")
                        .font(.system(size: 18))
                }

            VStack(alignment: .leading, spacing: 4) {
                if let prefix = prefix {
                    Text("\(prefix) \(text)")
                        .font(.subheadline)
                } else {
                    Text(text)
                        .font(.subheadline)
                }

                if let subtext = subtext {
                    Text(subtext)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(16)
    }
}

// MARK: - Text Mode View
struct TextModeView: View {
    @Binding var text: String
    let onAnalyze: () -> Void
    let onSaveWithoutAnalysis: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S ENTRY")
                .font(.caption)
                .tracking(1)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Text("New Memory")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 24)
                .padding(.top, 4)

            // Text Editor
            TextEditor(text: $text)
                .frame(minHeight: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("What happened today?")
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 40)
                            .padding(.top, 48)
                            .allowsHitTesting(false)
                    }
                }

            Text("\(text.count)/500")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            // Add Photos
            Text("📷 ADD PHOTOS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            PhotoAddButton()
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: onAnalyze) {
                    Text("✨ ✨ ANALYZE WITH AI")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(text.isEmpty ? Color.gray : Color.dmPrimary)
                        .cornerRadius(16)
                }
                .disabled(text.isEmpty)

                Button("Save without analysis", action: onSaveWithoutAnalysis)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Photo Add Button
struct PhotoAddButton: View {
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Text("+")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("UPLOAD")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(.secondary.opacity(0.3))
            )
        }
    }
}

// MARK: - AI Processing View
struct AIProcessingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("✨")
                .font(.system(size: 48))

            Text("AI is analyzing...")
                .font(.title2)
                .fontWeight(.bold)

            Text("Extracting people, places, and events")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - AI Result View
struct AIResultView: View {
    let result: AIAnalysisResultModel
    let onCategorySelect: (String) -> Void
    let onPersonRemove: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Content Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Memory")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button("Edit ✏️") {}
                            .foregroundColor(.dmPrimary)
                    }

                    Text(result.content)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(16)
                }

                // AI Analysis Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("✨ AI Analysis")
                        .font(.headline)
                        .foregroundColor(.dmPrimary)

                    VStack(spacing: 0) {
                        // People
                        AIResultRow(icon: "👤", label: "PEOPLE") {
                            HStack(spacing: 8) {
                                ForEach(result.people, id: \.self) { person in
                                    RecordPersonChipView(
                                        name: person,
                                        onRemove: { onPersonRemove(person) }
                                    )
                                }
                                Button("+ Add person") {}
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }

                        if result.newPersonDetected {
                            Text("ℹ️ New person detected. Set relationship?")
                                .font(.caption)
                                .foregroundColor(.dmPrimary)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }

                        Divider().padding(.horizontal, 16)

                        // Location
                        AIResultRow(icon: "📍", label: "LOCATION") {
                            HStack {
                                Text(result.location ?? "Not detected")
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Change >") {}
                                    .foregroundColor(.dmPrimary)
                            }
                        }

                        Divider().padding(.horizontal, 16)

                        // Event
                        AIResultRow(icon: "🎉", label: "EVENT") {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(result.event ?? "Not detected")
                                        .fontWeight(.medium)
                                    if let date = result.eventDate {
                                        Text(date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Button("Change >") {}
                                    .foregroundColor(.dmPrimary)
                            }
                        }

                        Divider().padding(.horizontal, 16)

                        // Amount
                        AIResultRow(icon: "💳", label: "AMOUNT") {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(result.amount ?? "Not detected")
                                        .fontWeight(.medium)
                                    if let label = result.amountLabel {
                                        Text(label)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Button("Change >") {}
                                    .foregroundColor(.dmPrimary)
                            }
                        }

                        Divider().padding(.horizontal, 16)

                        // Category
                        AIResultRow(icon: "🏷️", label: "CATEGORY") {
                            HStack(spacing: 8) {
                                ForEach(["General", "Meeting", "Event", "Financial"], id: \.self) { category in
                                    CategoryChipView(
                                        label: category,
                                        isSelected: result.category == category,
                                        onTap: { onCategorySelect(category) }
                                    )
                                }
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }

                // Add Photos
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Photos")
                        .font(.headline)

                    PhotoAddButton()
                }

                // Reminder Section
                if let reminder = result.suggestedReminder {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🔔")
                            Text("Set Reminder")
                                .fontWeight(.bold)
                            Button("Setup >") {}
                                .foregroundColor(.dmPrimary)
                            Spacer()
                        }

                        HStack {
                            Text("💡")
                            Text(reminder)
                        }
                        .font(.subheadline)

                        Button("Yes, remind me 1 day before") {}
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.dmPrimary)
                            .cornerRadius(20)
                    }
                    .padding(20)
                    .background(Color.dmPrimary.opacity(0.1))
                    .cornerRadius(16)
                }

                Spacer(minLength: 100)
            }
            .padding(24)
        }
    }
}

// MARK: - AI Result Row
struct AIResultRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(icon) \(label)")
                .font(.caption)
                .tracking(1)
                .foregroundColor(.secondary)

            content
        }
        .padding(16)
    }
}

// MARK: - Person Chip View
private struct RecordPersonChipView: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
            Button(action: onRemove) {
                Text("×")
            }
        }
        .font(.subheadline)
        .foregroundColor(.dmPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.dmPrimary.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Category Chip View
struct CategoryChipView: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.dmPrimary : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - View Model
@MainActor
class RecordViewModel: ObservableObject {
    @Published var recordState: RecordState = .voiceIdle
    @Published var recordingTime: String = "0:00"
    @Published var transcription: String = ""
    @Published var textContent: String = ""
    @Published var aiResult: AIAnalysisResultModel?
    @Published var isSaving: Bool = false
    @Published var error: String?

    private let saveMemoryUseCase: SaveMemoryUseCase
    private let savePersonUseCase: SavePersonUseCase
    private let getAllPersonsUseCase: GetAllPersonsUseCase

    private var timerTask: Task<Void, Never>?
    private var recordingSeconds = 0
    private var existingPersons: [Person] = []

    init(
        saveMemoryUseCase: SaveMemoryUseCase = DIContainer.shared.saveMemoryUseCase,
        savePersonUseCase: SavePersonUseCase = DIContainer.shared.savePersonUseCase,
        getAllPersonsUseCase: GetAllPersonsUseCase = DIContainer.shared.getAllPersonsUseCase
    ) {
        self.saveMemoryUseCase = saveMemoryUseCase
        self.savePersonUseCase = savePersonUseCase
        self.getAllPersonsUseCase = getAllPersonsUseCase

        Task {
            await loadExistingPersons()
        }
    }

    private func loadExistingPersons() async {
        do {
            existingPersons = try await getAllPersonsUseCase.execute()
        } catch {
            existingPersons = []
        }
    }

    func toggleMode() {
        switch recordState {
        case .voiceIdle, .voiceRecording:
            stopRecording()
            recordState = .textMode
        case .textMode:
            recordState = .voiceIdle
        default:
            break
        }
    }

    func startRecording() {
        recordState = .voiceRecording
        transcription = ""
        recordingSeconds = 0

        // Start timer
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                recordingSeconds += 1
                let minutes = recordingSeconds / 60
                let seconds = recordingSeconds % 60
                recordingTime = String(format: "%d:%02d", minutes, seconds)
            }
        }

        // Simulate transcription (TODO: Replace with actual speech recognition)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            transcription = "Had lunch with "
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            transcription = "Had lunch with Mike "
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            transcription = "Had lunch with Mike downtown. He told me "
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            transcription = "Had lunch with Mike downtown. He told me he's getting married next month. "
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            transcription = "Had lunch with Mike downtown. He told me he's getting married next month. Need to prepare a wedding gift around 300 dollars..."
        }
    }

    func stopRecording() {
        timerTask?.cancel()
        timerTask = nil

        if !transcription.isEmpty {
            textContent = transcription
            recordState = .aiProcessing
            analyzeWithAI()
        } else {
            recordState = .voiceIdle
        }
    }

    func analyzeWithAI() {
        recordState = .aiProcessing

        Task {
            // TODO: Replace with actual AI analysis service
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            let content = textContent.isEmpty ? transcription : textContent

            // Check for new persons
            let detectedPeople = ["Mike"] // TODO: Extract from AI
            let newPersonDetected = detectedPeople.contains { detected in
                !existingPersons.contains { $0.name.lowercased() == detected.lowercased() }
            }

            aiResult = AIAnalysisResultModel(
                content: content.isEmpty ?
                    "Had lunch with Mike downtown. He told me he's getting married next month. Need to prepare a wedding gift around 300 dollars." : content,
                people: detectedPeople,
                newPersonDetected: newPersonDetected,
                location: "Downtown",
                event: "Wedding",
                eventDate: "Next month",
                amount: "$300",
                amountLabel: "Gift budget",
                category: "Event",
                suggestedReminder: "Remind you before the wedding?"
            )

            recordState = .aiResult
        }
    }

    func saveWithoutAnalysis() {
        guard !textContent.isEmpty else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            let memory = Memory(
                content: textContent,
                photos: [],
                extractedPersons: [],
                extractedLocation: nil,
                extractedDate: nil,
                extractedAmount: nil,
                extractedTags: [],
                personIds: [],
                category: .general,
                importance: 3,
                recordedAt: Date()
            )

            do {
                try await saveMemoryUseCase.execute(memory)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func saveMemory() {
        guard let result = aiResult else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            // Save new persons if detected
            for personName in result.people {
                let isExisting = existingPersons.contains { $0.name.lowercased() == personName.lowercased() }
                if !isExisting {
                    let newPerson = Person(
                        name: personName,
                        relationship: .friend,
                        meetingCount: 1,
                        lastMeetingDate: Date()
                    )
                    do {
                        try await savePersonUseCase.execute(newPerson)
                    } catch {
                        print("Failed to save person: \(error)")
                    }
                }
            }

            // Extract amount value
            let amountValue: Double? = {
                guard let amountStr = result.amount else { return nil }
                let numericStr = amountStr.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                return Double(numericStr)
            }()

            // Determine category from result
            let category = Category(rawValue: result.category.uppercased()) ?? .general

            // Create and save memory
            let memory = Memory(
                content: result.content,
                photos: [],
                extractedPersons: result.people,
                extractedLocation: result.location,
                extractedDate: nil,
                extractedAmount: amountValue,
                extractedTags: [],
                personIds: [],
                category: category,
                importance: 3,
                recordedAt: Date()
            )

            do {
                try await saveMemoryUseCase.execute(memory)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func selectCategory(_ category: String) {
        aiResult?.category = category
    }

    func togglePerson(_ person: String) {
        guard var result = aiResult else { return }
        if result.people.contains(person) {
            result.people.removeAll { $0 == person }
        } else {
            result.people.append(person)
        }
        aiResult = result
    }

    func clearError() {
        error = nil
    }
}

enum RecordState {
    case voiceIdle
    case voiceRecording
    case textMode
    case aiProcessing
    case aiResult
}

class AIAnalysisResultModel: ObservableObject {
    var content: String
    var people: [String]
    var newPersonDetected: Bool
    var location: String?
    var event: String?
    var eventDate: String?
    var amount: String?
    var amountLabel: String?
    var category: String
    var suggestedReminder: String?

    init(
        content: String,
        people: [String],
        newPersonDetected: Bool = false,
        location: String? = nil,
        event: String? = nil,
        eventDate: String? = nil,
        amount: String? = nil,
        amountLabel: String? = nil,
        category: String = "General",
        suggestedReminder: String? = nil
    ) {
        self.content = content
        self.people = people
        self.newPersonDetected = newPersonDetected
        self.location = location
        self.event = event
        self.eventDate = eventDate
        self.amount = amount
        self.amountLabel = amountLabel
        self.category = category
        self.suggestedReminder = suggestedReminder
    }
}

#Preview {
    RecordView()
}
