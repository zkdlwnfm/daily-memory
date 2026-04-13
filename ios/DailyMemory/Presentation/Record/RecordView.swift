import SwiftUI
import PhotosUI

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecordViewModel()
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showSaveSuccess = false

    /// 위젯에서 진입 시 자동 녹음 시작
    var autoStartRecording: Bool = false
    /// 퀵 엔트리 모드로 시작
    var quickEntryMode: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                switch viewModel.recordState {
                case .quickEntry:
                    QuickEntryView(viewModel: viewModel) {
                        showSaveSuccess = true
                    }

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
                        photos: viewModel.selectedPhotos,
                        onAnalyze: { viewModel.analyzeWithAI() },
                        onSaveWithoutAnalysis: {
                            Task {
                                await viewModel.saveWithoutAnalysisAsync()
                                showSaveSuccess = true
                            }
                        },
                        onAddPhoto: { showPhotoPicker = true },
                        onRemovePhoto: { viewModel.removePhoto(id: $0) }
                    )

                case .aiProcessing:
                    AIProcessingView()

                case .aiResult:
                    if let result = viewModel.aiResult {
                        AIResultView(
                            result: result,
                            onCategorySelect: { viewModel.selectCategory($0) },
                            onPersonRemove: { viewModel.togglePerson($0) },
                            onAddPhoto: { showPhotoPicker = true },
                            onRemovePhoto: { viewModel.removePhoto(id: $0) }
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
                    case .quickEntry:
                        EmptyView()

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
                            Task {
                                await viewModel.saveMemoryAsync()
                                showSaveSuccess = true
                            }
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.dmPrimary)
                        .cornerRadius(20)
                        .disabled(viewModel.isSaving)

                    case .aiProcessing:
                        EmptyView()
                    }
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: selectedPhotoItems) { newItems in
                Task {
                    await viewModel.addPhotos(from: newItems)
                    selectedPhotoItems = []
                }
            }
            .overlay {
                SaveSuccessView(isPresented: $showSaveSuccess)
            }
            .onChange(of: showSaveSuccess) { showing in
                if !showing {
                    dismiss()
                }
            }
            .onAppear {
                if quickEntryMode {
                    viewModel.recordState = .quickEntry
                } else if autoStartRecording && viewModel.recordState == .voiceIdle {
                    viewModel.startRecording()
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

            Text("Engram is listening")
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
                text: "Speak naturally. Engram automatically organizes names, dates, and amounts mentioned.",
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
    let photos: [SelectedPhoto]
    let onAnalyze: () -> Void
    let onSaveWithoutAnalysis: () -> Void
    let onAddPhoto: () -> Void
    let onRemovePhoto: (String) -> Void

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

            if photos.isEmpty {
                PhotoAddButton(action: onAddPhoto)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            } else {
                SelectedPhotosView(
                    photos: photos,
                    onRemove: onRemovePhoto,
                    onAddMore: onAddPhoto
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }

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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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

// MARK: - Selected Photos View
struct SelectedPhotosView: View {
    let photos: [SelectedPhoto]
    let onRemove: (String) -> Void
    let onAddMore: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(photos) { photo in
                    ZStack(alignment: .topTrailing) {
                        if let image = photo.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    ProgressView()
                                }
                        }

                        // Remove button
                        Button {
                            onRemove(photo.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 5, y: -5)

                        // Analysis indicator
                        if photo.isAnalyzing {
                            VStack {
                                Spacer()
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                    Text("AI")
                                        .font(.caption2)
                                }
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                            }
                            .frame(width: 80, height: 80)
                        } else if photo.analysis != nil {
                            VStack {
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                    Text("AI")
                                        .font(.caption2)
                                }
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                            }
                            .frame(width: 80, height: 80)
                        }
                    }
                }

                // Add more button
                PhotoAddButton(action: onAddMore)
            }
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
    let onAddPhoto: () -> Void
    let onRemovePhoto: (String) -> Void

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
                            Text(result.location ?? "Not detected")
                                .fontWeight(.medium)
                        }

                        Divider().padding(.horizontal, 16)

                        // Event
                        AIResultRow(icon: "🎉", label: "EVENT") {
                            VStack(alignment: .leading) {
                                Text(result.event ?? "Not detected")
                                    .fontWeight(.medium)
                                if let date = result.eventDate {
                                    Text(date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Divider().padding(.horizontal, 16)

                        // Amount
                        AIResultRow(icon: "💳", label: "AMOUNT") {
                            VStack(alignment: .leading) {
                                Text(result.amount ?? "Not detected")
                                    .fontWeight(.medium)
                                if let label = result.amountLabel {
                                    Text(label)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
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

                    if result.photos.isEmpty {
                        PhotoAddButton(action: onAddPhoto)
                    } else {
                        SelectedPhotosView(
                            photos: result.photos,
                            onRemove: onRemovePhoto,
                            onAddMore: onAddPhoto
                        )
                    }
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

// MARK: - Selected Photo Model
struct SelectedPhoto: Identifiable, Equatable {
    let id: String
    var image: UIImage?
    var savedPhoto: SavedPhoto?
    var analysis: PhotoAnalysis?
    var isAnalyzing: Bool = false

    static func == (lhs: SelectedPhoto, rhs: SelectedPhoto) -> Bool {
        lhs.id == rhs.id
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
    @Published var audioLevel: Float = 0
    @Published var selectedPhotos: [SelectedPhoto] = []

    private let saveMemoryUseCase: SaveMemoryUseCase
    private let savePersonUseCase: SavePersonUseCase
    private let getAllPersonsUseCase: GetAllPersonsUseCase
    private let analyzeImageUseCase: AnalyzeImageUseCase

    private var timerTask: Task<Void, Never>?
    private var speechTask: Task<Void, Never>?
    private var recordingSeconds = 0
    private var existingPersons: [Person] = []
    private let speechService = SpeechRecognitionService.shared
    private let aiAnalysisService = AIAnalysisService.shared

    init(
        saveMemoryUseCase: SaveMemoryUseCase = DIContainer.shared.saveMemoryUseCase,
        savePersonUseCase: SavePersonUseCase = DIContainer.shared.savePersonUseCase,
        getAllPersonsUseCase: GetAllPersonsUseCase = DIContainer.shared.getAllPersonsUseCase,
        analyzeImageUseCase: AnalyzeImageUseCase = DIContainer.shared.analyzeImageUseCase
    ) {
        self.saveMemoryUseCase = saveMemoryUseCase
        self.savePersonUseCase = savePersonUseCase
        self.getAllPersonsUseCase = getAllPersonsUseCase
        self.analyzeImageUseCase = analyzeImageUseCase

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

        // Real speech recognition
        speechTask = Task {
            let stream = await speechService.startListening()
            for await result in stream {
                switch result {
                case .partialResult(let text):
                    transcription = text
                case .finalResult(let text, _):
                    transcription = text
                case .audioLevel(let level):
                    audioLevel = level
                case .error(let msg):
                    error = msg
                case .ready:
                    break
                }
            }
        }
    }

    func stopRecording() {
        timerTask?.cancel()
        timerTask = nil
        speechTask?.cancel()
        speechTask = nil

        Task { await speechService.stopListening() }

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
            let content = textContent.isEmpty ? transcription : textContent

            // Call actual AI analysis service (backend API)
            let analysisResult = await aiAnalysisService.analyzeText(content)

            // Collect tags from photo analyses
            var photoTags: [String] = []
            for photo in selectedPhotos {
                if let analysis = photo.analysis {
                    photoTags.append(contentsOf: analysis.suggestedTags)
                }
            }
            photoTags = Array(Set(photoTags))

            switch analysisResult {
            case .success(let result):
                let detectedPeople = result.persons
                let newPersonDetected = detectedPeople.contains { detected in
                    !existingPersons.contains { $0.name.lowercased() == detected.lowercased() }
                }

                let amountStr = result.amount.map { String(format: "$%.0f", $0) }

                aiResult = AIAnalysisResultModel(
                    content: content,
                    people: detectedPeople,
                    personsWithRelationship: result.personsWithRelationship,
                    newPersonDetected: newPersonDetected,
                    location: result.location,
                    event: result.tags.first,
                    eventDate: result.date,
                    amount: amountStr,
                    amountLabel: result.amount != nil ? "Amount" : nil,
                    category: result.category,
                    suggestedReminder: nil,
                    photos: selectedPhotos,
                    photoTags: photoTags + result.tags
                )

            case .failure:
                // Fallback with minimal data
                aiResult = AIAnalysisResultModel(
                    content: content,
                    people: [],
                    newPersonDetected: false,
                    location: nil,
                    event: nil,
                    eventDate: nil,
                    amount: nil,
                    amountLabel: nil,
                    category: "GENERAL",
                    suggestedReminder: nil,
                    photos: selectedPhotos,
                    photoTags: photoTags
                )
            }

            recordState = .aiResult
        }
    }

    func saveWithoutAnalysis() {
        Task {
            await saveWithoutAnalysisAsync()
        }
    }

    func saveWithoutAnalysisAsync() async {
        guard !textContent.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let content = textContent

        // Collect photos and tags from analyzed photos
        let photos: [Photo] = selectedPhotos.compactMap { selected in
            guard let saved = selected.savedPhoto else { return nil }
            return Photo(id: saved.id, url: saved.url.path, thumbnailUrl: saved.thumbnailUrl.path)
        }
        var photoTags: [String] = []
        for photo in selectedPhotos {
            if let analysis = photo.analysis {
                photoTags.append(contentsOf: analysis.suggestedTags)
            }
        }
        photoTags = Array(Set(photoTags))

        let memory = Memory(
            content: content,
            photos: photos,
            extractedPersons: [],
            extractedLocation: nil,
            extractedDate: nil,
            extractedAmount: nil,
            extractedTags: photoTags,
            personIds: [],
            category: .general,
            importance: 3,
            recordedAt: Date()
        )

        do {
            _ = try await saveMemoryUseCase.execute(memory)

            // Background AI analysis - update memory after analysis completes
            let memoryId = memory.id
            let savedPhotos = selectedPhotos
            Task.detached { [weak self] in
                guard let self else { return }
                await self.backgroundAnalyze(memoryId: memoryId, content: content, photos: savedPhotos)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Run AI analysis in background and update the saved memory
    /// 퀵 엔트리 저장
    func saveQuickEntryAsync(content: String, mood: String?, moodScore: Int?, tags: [String]) async {
        isSaving = true
        defer { isSaving = false }

        let memory = Memory(
            content: content,
            photos: [],
            extractedPersons: [],
            extractedLocation: nil,
            extractedDate: nil,
            extractedAmount: nil,
            extractedTags: tags,
            personIds: [],
            category: .general,
            importance: 3,
            mood: mood,
            moodScore: moodScore,
            recordedAt: Date()
        )

        do {
            _ = try await saveMemoryUseCase.execute(memory)
            let memoryId = memory.id
            Task.detached { [weak self] in
                guard let self else { return }
                await self.backgroundAnalyze(memoryId: memoryId, content: content, photos: [])
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func backgroundAnalyze(memoryId: String, content: String, photos: [SelectedPhoto]) async {
        let analysisResult = await aiAnalysisService.analyzeText(content)

        guard case .success(let result) = analysisResult else { return }

        // Build updated memory
        let container = DIContainer.shared
        do {
            guard var memory = try await container.getMemoryUseCase.execute(id: memoryId) else { return }

            memory.extractedPersons = result.persons
            memory.extractedLocation = result.location
            memory.extractedAmount = result.amount
            memory.extractedTags = result.tags
            memory.category = Category(rawValue: result.category) ?? .general
            memory.mood = result.mood
            memory.moodScore = result.moodScore

            _ = try await container.updateMemoryUseCase.execute(memory)

            // Save new persons
            let existingPersons = try await container.getAllPersonsUseCase.execute()
            for person in result.personsWithRelationship {
                let isExisting = existingPersons.contains { $0.name.lowercased() == person.name.lowercased() }
                if !isExisting {
                    let newPerson = Person(name: person.name, relationship: person.relationship, meetingCount: 1, lastMeetingDate: Date())
                    _ = try await container.savePersonUseCase.execute(newPerson)
                }
            }

        } catch {
        }
    }

    func saveMemory() {
        Task {
            await saveMemoryAsync()
        }
    }

    func saveMemoryAsync() async {
        guard let result = aiResult else { return }

        isSaving = true
        defer { isSaving = false }

        // Save new persons if detected
        for personName in result.people {
            let isExisting = existingPersons.contains { $0.name.lowercased() == personName.lowercased() }
            if !isExisting {
                // Look up relationship from AI analysis
                let relationship = result.personsWithRelationship
                    .first { $0.name.lowercased() == personName.lowercased() }?
                    .relationship ?? .other

                let newPerson = Person(
                    name: personName,
                    relationship: relationship,
                    meetingCount: 1,
                    lastMeetingDate: Date()
                )
                do {
                    _ = try await savePersonUseCase.execute(newPerson)
                } catch {
                    // Person save failed, continue with memory save
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

        // Collect photos and combine tags
        let photos: [Photo] = result.photos.compactMap { selected in
            guard let saved = selected.savedPhoto else { return nil }
            return Photo(id: saved.id, url: saved.url.path, thumbnailUrl: saved.thumbnailUrl.path)
        }
        var allTags = result.photoTags

        // Create and save memory
        let memory = Memory(
            content: result.content,
            photos: photos,
            extractedPersons: result.people,
            extractedLocation: result.location,
            extractedDate: nil,
            extractedAmount: amountValue,
            extractedTags: allTags,
            personIds: [],
            category: category,
            importance: 3,
            recordedAt: Date()
        )

        do {
            _ = try await saveMemoryUseCase.execute(memory)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectCategory(_ category: String) {
        aiResult?.category = category
    }

    func togglePerson(_ person: String) {
        guard let result = aiResult else { return }
        if result.people.contains(person) {
            result.people.removeAll { $0 == person }
        } else {
            result.people.append(person)
        }
    }

    func clearError() {
        error = nil
    }

    // MARK: - Photo Management

    func addPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            let photoId = UUID().uuidString
            var selectedPhoto = SelectedPhoto(id: photoId)

            // Add placeholder immediately
            selectedPhotos.append(selectedPhoto)

            // Load image data
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {

                // Update with image
                if let index = selectedPhotos.firstIndex(where: { $0.id == photoId }) {
                    selectedPhotos[index].image = image
                    selectedPhotos[index].isAnalyzing = true
                }

                // Save to PhotoService
                let saveResult = await PhotoService.shared.savePhoto(image: image)
                if case .success(let savedPhoto) = saveResult {
                    if let index = selectedPhotos.firstIndex(where: { $0.id == photoId }) {
                        selectedPhotos[index].savedPhoto = savedPhoto
                    }
                }

                // Analyze image with AI
                let analysisResult = await analyzeImageUseCase.execute(image: image)
                if let index = selectedPhotos.firstIndex(where: { $0.id == photoId }) {
                    selectedPhotos[index].isAnalyzing = false
                    if case .success(let analysis) = analysisResult {
                        selectedPhotos[index].analysis = analysis
                    }
                }

                // Also update aiResult photos if in aiResult state
                if recordState == .aiResult, let result = aiResult {
                    result.photos = selectedPhotos
                }
            }
        }
    }

    func removePhoto(id: String) {
        selectedPhotos.removeAll { $0.id == id }

        // Also update aiResult photos if in aiResult state
        if let result = aiResult {
            result.photos = selectedPhotos
        }
    }
}

enum RecordState {
    case voiceIdle
    case voiceRecording
    case textMode
    case quickEntry
    case aiProcessing
    case aiResult
}

class AIAnalysisResultModel: ObservableObject {
    var content: String
    var people: [String]
    var personsWithRelationship: [PersonWithRelationship]
    var newPersonDetected: Bool
    var location: String?
    var event: String?
    var eventDate: String?
    var amount: String?
    var amountLabel: String?
    var category: String
    var suggestedReminder: String?
    var photos: [SelectedPhoto]
    var photoTags: [String]

    init(
        content: String,
        people: [String],
        personsWithRelationship: [PersonWithRelationship] = [],
        newPersonDetected: Bool = false,
        location: String? = nil,
        event: String? = nil,
        eventDate: String? = nil,
        amount: String? = nil,
        amountLabel: String? = nil,
        category: String = "General",
        suggestedReminder: String? = nil,
        photos: [SelectedPhoto] = [],
        photoTags: [String] = []
    ) {
        self.content = content
        self.people = people
        self.personsWithRelationship = personsWithRelationship
        self.newPersonDetected = newPersonDetected
        self.location = location
        self.event = event
        self.eventDate = eventDate
        self.amount = amount
        self.amountLabel = amountLabel
        self.category = category
        self.suggestedReminder = suggestedReminder
        self.photos = photos
        self.photoTags = photoTags
    }
}

// MARK: - Quick Entry View

struct QuickEntryView: View {
    @ObservedObject var viewModel: RecordViewModel
    let onSaved: () -> Void

    @State private var selectedMood: String?
    @State private var selectedActivities: Set<String> = []
    @State private var quickNote: String = ""
    @State private var isSaving = false

    private let moods: [(emoji: String, label: String, value: String)] = [
        ("😊", "Great", "happy"),
        ("🙂", "Good", "calm"),
        ("😐", "Okay", "neutral"),
        ("😔", "Low", "sad"),
        ("😤", "Stressed", "anxious")
    ]

    private let activities: [(icon: String, label: String)] = [
        ("figure.run", "Exercise"),
        ("briefcase.fill", "Work"),
        ("person.2.fill", "Social"),
        ("fork.knife", "Food"),
        ("book.fill", "Reading"),
        ("gamecontroller.fill", "Gaming"),
        ("music.note", "Music"),
        ("cart.fill", "Shopping"),
        ("bed.double.fill", "Rest"),
        ("airplane", "Travel"),
        ("heart.fill", "Date"),
        ("ellipsis", "Other")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                // Mood Section
                VStack(spacing: Spacing.md) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: Spacing.md) {
                        ForEach(moods, id: \.value) { mood in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedMood = mood.value
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: Spacing.xs) {
                                    Text(mood.emoji)
                                        .font(.system(size: selectedMood == mood.value ? 40 : 32))
                                        .scaleEffect(selectedMood == mood.value ? 1.15 : 1.0)

                                    Text(mood.label)
                                        .font(.caption2)
                                        .fontWeight(selectedMood == mood.value ? .bold : .regular)
                                        .foregroundColor(selectedMood == mood.value ? .dmPrimary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .fill(selectedMood == mood.value ? Color.dmPrimary.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, Spacing.lg)

                // Activities Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("What have you been up to?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4), spacing: Spacing.sm) {
                        ForEach(activities, id: \.label) { activity in
                            let isSelected = selectedActivities.contains(activity.label)
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    if isSelected {
                                        selectedActivities.remove(activity.label)
                                    } else {
                                        selectedActivities.insert(activity.label)
                                    }
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: Spacing.xs) {
                                    Image(systemName: activity.icon)
                                        .font(.system(size: 18))
                                        .frame(height: 22)
                                    Text(activity.label)
                                        .font(.system(size: 10, weight: .medium))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm + 2)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .fill(isSelected ? Color.dmPrimary.opacity(0.12) : Color(.systemGray6))
                                )
                                .foregroundColor(isSelected ? .dmPrimary : .secondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .stroke(isSelected ? Color.dmPrimary.opacity(0.3) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Quick Note
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Quick note")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    TextField("What's on your mind? (optional)", text: $quickNote, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(Spacing.md)
                        .background(Color(.systemGray6))
                        .cornerRadius(Radius.md)
                }

                // Save Button
                Button {
                    Task {
                        isSaving = true
                        await saveQuickEntry()
                        isSaving = false
                        onSaved()
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Save")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(selectedMood != nil ? Color.dmPrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(Radius.md)
                }
                .disabled(selectedMood == nil || isSaving)

                Spacer(minLength: Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private func saveQuickEntry() async {
        let moodEmoji = moods.first(where: { $0.value == selectedMood })?.emoji ?? ""
        let activitiesText = selectedActivities.isEmpty ? "" : " | " + selectedActivities.joined(separator: ", ")
        let noteText = quickNote.isEmpty ? "" : " | " + quickNote
        let content = "\(moodEmoji)\(activitiesText)\(noteText)"

        await viewModel.saveQuickEntryAsync(
            content: content,
            mood: selectedMood,
            moodScore: moodToScore(selectedMood),
            tags: Array(selectedActivities)
        )
    }

    private func moodToScore(_ mood: String?) -> Int? {
        switch mood {
        case "happy": return 9
        case "calm": return 7
        case "neutral": return 5
        case "sad": return 3
        case "anxious": return 2
        default: return nil
        }
    }
}

#Preview {
    RecordView()
}
