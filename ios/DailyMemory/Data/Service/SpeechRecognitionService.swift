import Foundation
import Speech
import AVFoundation
import Combine

/// Speech Recognition Service using Apple's Speech Framework
@MainActor
final class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()

    // MARK: - Published Properties
    @Published private(set) var state: SpeechRecognitionState = .idle
    @Published private(set) var partialResult: String = ""
    @Published private(set) var audioLevel: Float = 0

    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    private var resultContinuation: AsyncStream<SpeechRecognitionResult>.Continuation?

    // MARK: - Initialization
    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    }

    // MARK: - Public Methods

    /// Check if speech recognition is available
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }

    /// Request authorization for speech recognition
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Request authorization for microphone access
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Check current authorization status
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    /// Start listening for speech input
    func startListening(language: String? = nil) -> AsyncStream<SpeechRecognitionResult> {
        AsyncStream { continuation in
            self.resultContinuation = continuation

            Task { @MainActor in
                do {
                    try await self.startRecognition(language: language)
                } catch {
                    continuation.yield(.error(error.localizedDescription))
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }
    }

    /// Stop listening and release resources
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        state = .idle
        partialResult = ""
        audioLevel = 0

        resultContinuation?.finish()
        resultContinuation = nil
    }

    /// Cancel current recognition
    func cancel() {
        recognitionTask?.cancel()
        stopListening()
    }

    // MARK: - Private Methods

    private func startRecognition(language: String?) async throws {
        // Configure speech recognizer for specific language if provided
        if let language = language {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.notAvailable
        }

        // Check authorization
        let authStatus = authorizationStatus
        guard authStatus == .authorized else {
            throw SpeechRecognitionError.notAuthorized
        }

        state = .starting

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true

        // On-device recognition if available (iOS 13+)
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }

        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechRecognitionError.audioEngineCreationFailed
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level for visualization
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            Task { @MainActor in
                self?.audioLevel = level
                self?.resultContinuation?.yield(.audioLevel(level))
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        state = .listening
        resultContinuation?.yield(.ready)

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }
    }

    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            let nsError = error as NSError

            // Handle specific errors
            if nsError.domain == "kAFAssistantErrorDomain" {
                switch nsError.code {
                case 203: // No speech detected
                    state = .idle
                    resultContinuation?.yield(.error("No speech detected"))
                case 209: // Retry
                    return
                default:
                    state = .error(error.localizedDescription)
                    resultContinuation?.yield(.error(error.localizedDescription))
                }
            } else {
                state = .error(error.localizedDescription)
                resultContinuation?.yield(.error(error.localizedDescription))
            }
            return
        }

        guard let result = result else { return }

        let transcription = result.bestTranscription.formattedString

        if result.isFinal {
            state = .idle
            let confidence = result.bestTranscription.segments.first?.confidence ?? 0
            resultContinuation?.yield(.finalResult(transcription, confidence))
            stopListening()
        } else {
            state = .recording
            partialResult = transcription
            resultContinuation?.yield(.partialResult(transcription))
        }
    }

    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        ).map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)

        // Normalize to 0-1 range (assuming -60dB to 0dB range)
        let normalizedLevel = max(0, min(1, (avgPower + 60) / 60))
        return normalizedLevel
    }
}

// MARK: - Speech Recognition State
enum SpeechRecognitionState: Equatable {
    case idle
    case starting
    case listening
    case recording
    case processing
    case error(String)

    var isActive: Bool {
        switch self {
        case .starting, .listening, .recording, .processing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Speech Recognition Result
enum SpeechRecognitionResult {
    case ready
    case audioLevel(Float)
    case partialResult(String)
    case finalResult(String, Float) // text, confidence
    case error(String)
}

// MARK: - Speech Recognition Error
enum SpeechRecognitionError: LocalizedError {
    case notAvailable
    case notAuthorized
    case requestCreationFailed
    case audioEngineCreationFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Speech recognition is not available on this device"
        case .notAuthorized:
            return "Speech recognition is not authorized"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .audioEngineCreationFailed:
            return "Failed to create audio engine"
        }
    }
}
