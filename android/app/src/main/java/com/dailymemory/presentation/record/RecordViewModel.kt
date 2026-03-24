package com.dailymemory.presentation.record

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.data.remote.AIAnalysisService
import com.dailymemory.data.service.SpeechRecognitionResult
import com.dailymemory.data.service.SpeechRecognitionService
import com.dailymemory.data.service.SpeechRecognitionState
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.usecase.ai.AnalyzeMemoryUseCase
import com.dailymemory.domain.usecase.memory.SaveMemoryUseCase
import com.dailymemory.domain.usecase.person.GetAllPersonsUseCase
import com.dailymemory.domain.usecase.person.SavePersonUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import javax.inject.Inject

@HiltViewModel
class RecordViewModel @Inject constructor(
    private val saveMemoryUseCase: SaveMemoryUseCase,
    private val savePersonUseCase: SavePersonUseCase,
    private val getAllPersonsUseCase: GetAllPersonsUseCase,
    private val speechRecognitionService: SpeechRecognitionService,
    private val analyzeMemoryUseCase: AnalyzeMemoryUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(RecordUiState())
    val uiState: StateFlow<RecordUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null
    private var speechJob: Job? = null
    private var recordingSeconds = 0

    // Cached persons for quick lookup
    private var existingPersons: List<Person> = emptyList()

    // Speech recognition availability
    val isSpeechAvailable: Boolean
        get() = speechRecognitionService.isAvailable()

    val hasMicrophonePermission: Boolean
        get() = speechRecognitionService.hasPermission()

    init {
        loadExistingPersons()
    }

    private fun loadExistingPersons() {
        viewModelScope.launch {
            try {
                existingPersons = getAllPersonsUseCase().first()
            } catch (e: Exception) {
                // Ignore errors during initial load
            }
        }
    }

    fun toggleMode() {
        _uiState.update { state ->
            when (state.recordState) {
                RecordState.VOICE_IDLE, RecordState.VOICE_RECORDING -> {
                    stopRecording()
                    state.copy(recordState = RecordState.TEXT_MODE)
                }
                RecordState.TEXT_MODE -> state.copy(recordState = RecordState.VOICE_IDLE)
                else -> state
            }
        }
    }

    fun startRecording() {
        if (!speechRecognitionService.hasPermission()) {
            _uiState.update { it.copy(error = "Microphone permission required") }
            return
        }

        _uiState.update { it.copy(
            recordState = RecordState.VOICE_RECORDING,
            transcription = ""
        )}

        // Start timer
        recordingSeconds = 0
        timerJob = viewModelScope.launch {
            while (true) {
                delay(1000)
                recordingSeconds++
                val minutes = recordingSeconds / 60
                val seconds = recordingSeconds % 60
                _uiState.update { it.copy(
                    recordingTime = String.format("%d:%02d", minutes, seconds)
                )}
            }
        }

        // Start speech recognition
        speechJob = viewModelScope.launch {
            speechRecognitionService.startListening().collect { result ->
                when (result) {
                    is SpeechRecognitionResult.Ready -> {
                        // Recognition ready
                    }
                    is SpeechRecognitionResult.PartialResult -> {
                        _uiState.update { it.copy(transcription = result.text) }
                    }
                    is SpeechRecognitionResult.FinalResult -> {
                        _uiState.update { it.copy(
                            transcription = result.text,
                            textContent = result.text
                        )}
                        // Auto-stop after final result
                        stopRecording()
                    }
                    is SpeechRecognitionResult.AudioLevel -> {
                        // Can be used for visualization
                        _uiState.update { it.copy(audioLevel = result.level) }
                    }
                    is SpeechRecognitionResult.Error -> {
                        _uiState.update { it.copy(error = result.message) }
                        // Don't stop on error, let user continue or retry
                    }
                }
            }
        }
    }

    fun stopRecording() {
        timerJob?.cancel()
        timerJob = null
        speechJob?.cancel()
        speechJob = null
        speechRecognitionService.stopListening()

        val transcription = _uiState.value.transcription
        if (transcription.isNotEmpty()) {
            _uiState.update { it.copy(
                recordState = RecordState.AI_PROCESSING,
                textContent = transcription
            )}
            analyzeWithAI()
        } else {
            _uiState.update { it.copy(recordState = RecordState.VOICE_IDLE) }
        }
    }

    fun updateText(text: String) {
        if (text.length <= 500) {
            _uiState.update { it.copy(textContent = text) }
        }
    }

    fun analyzeWithAI() {
        _uiState.update { it.copy(recordState = RecordState.AI_PROCESSING) }

        viewModelScope.launch {
            val content = _uiState.value.textContent.ifEmpty {
                _uiState.value.transcription
            }

            if (content.isBlank()) {
                _uiState.update { it.copy(
                    recordState = RecordState.VOICE_IDLE,
                    error = "No content to analyze"
                )}
                return@launch
            }

            // Use AI analysis service
            analyzeMemoryUseCase(content)
                .onSuccess { analysis ->
                    // Check if any person is new
                    val existingNames = existingPersons.map { it.name.lowercase() }
                    val newPersons = analysis.persons.filter { !existingNames.contains(it.lowercase()) }

                    _uiState.update { it.copy(
                        recordState = RecordState.AI_RESULT,
                        aiResult = AIAnalysisResult(
                            content = content,
                            people = analysis.persons,
                            newPersonDetected = newPersons.isNotEmpty(),
                            location = analysis.location,
                            event = if (analysis.category == Category.EVENT) "Event detected" else null,
                            eventDate = analysis.date?.let { formatDate(it) },
                            amount = analysis.amount?.let { "$$it" },
                            amountLabel = if (analysis.amount != null) "Amount mentioned" else null,
                            category = analysis.category.name.lowercase()
                                .replaceFirstChar { it.uppercase() },
                            suggestedReminder = generateReminderSuggestion(content)
                        )
                    )}
                }
                .onFailure { e ->
                    // Fallback to simple extraction on error
                    val extractedPeople = extractPeople(content)
                    val extractedLocation = extractLocation(content)
                    val extractedAmount = extractAmount(content)
                    val category = determineCategory(content)

                    val existingNames = existingPersons.map { it.name.lowercase() }
                    val newPersons = extractedPeople.filter { !existingNames.contains(it.lowercase()) }

                    _uiState.update { it.copy(
                        recordState = RecordState.AI_RESULT,
                        aiResult = AIAnalysisResult(
                            content = content,
                            people = extractedPeople,
                            newPersonDetected = newPersons.isNotEmpty(),
                            location = extractedLocation,
                            event = if (content.contains("wedding", ignoreCase = true) ||
                                      content.contains("birthday", ignoreCase = true)) "Event detected" else null,
                            eventDate = extractEventDate(content),
                            amount = extractedAmount?.let { "$$it" },
                            amountLabel = if (extractedAmount != null) "Amount mentioned" else null,
                            category = category,
                            suggestedReminder = generateReminderSuggestion(content)
                        )
                    )}
                }
        }
    }

    private fun formatDate(dateTime: LocalDateTime): String {
        val now = LocalDateTime.now()
        return when {
            dateTime.toLocalDate() == now.toLocalDate() -> "Today"
            dateTime.toLocalDate() == now.plusDays(1).toLocalDate() -> "Tomorrow"
            dateTime.month == now.plusMonths(1).month -> "Next month"
            else -> dateTime.format(java.time.format.DateTimeFormatter.ofPattern("MMM d"))
        }
    }

    fun saveWithoutAnalysis(onComplete: () -> Unit) {
        viewModelScope.launch {
            val content = _uiState.value.textContent.ifEmpty {
                _uiState.value.transcription
            }

            if (content.isBlank()) {
                _uiState.update { it.copy(error = "Cannot save empty memory") }
                return@launch
            }

            val memory = Memory(
                content = content,
                category = Category.GENERAL,
                recordedAt = LocalDateTime.now()
            )

            saveMemoryUseCase(memory)
                .onSuccess {
                    onComplete()
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message) }
                }
        }
    }

    fun saveMemory(onComplete: () -> Unit) {
        viewModelScope.launch {
            val aiResult = _uiState.value.aiResult ?: return@launch

            // Create new persons if detected
            val newPersonIds = mutableListOf<String>()

            for (personName in aiResult.people) {
                val existingPerson = existingPersons.find {
                    it.name.equals(personName, ignoreCase = true)
                }

                if (existingPerson != null) {
                    newPersonIds.add(existingPerson.id)
                } else {
                    // Create new person
                    val newPerson = Person(
                        name = personName,
                        relationship = Relationship.OTHER
                    )
                    savePersonUseCase(newPerson)
                        .onSuccess {
                            newPersonIds.add(newPerson.id)
                        }
                }
            }

            // Create memory
            val memory = Memory(
                content = aiResult.content,
                extractedPersons = aiResult.people,
                extractedLocation = aiResult.location,
                extractedAmount = aiResult.amount?.replace("$", "")?.toDoubleOrNull(),
                personIds = newPersonIds,
                category = Category.fromString(aiResult.category),
                recordedAt = LocalDateTime.now()
            )

            saveMemoryUseCase(memory)
                .onSuccess {
                    onComplete()
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message) }
                }
        }
    }

    fun editContent(newContent: String) {
        _uiState.update { state ->
            state.copy(
                aiResult = state.aiResult?.copy(content = newContent)
            )
        }
    }

    fun togglePerson(person: String) {
        _uiState.update { state ->
            val currentPeople = state.aiResult?.people ?: emptyList()
            val newPeople = if (currentPeople.contains(person)) {
                currentPeople - person
            } else {
                currentPeople + person
            }
            state.copy(
                aiResult = state.aiResult?.copy(people = newPeople)
            )
        }
    }

    fun selectCategory(category: String) {
        _uiState.update { state ->
            state.copy(
                aiResult = state.aiResult?.copy(category = category)
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        speechJob?.cancel()
        speechRecognitionService.stopListening()
    }

    // Simple extraction helpers (to be replaced with AI)
    private fun extractPeople(content: String): List<String> {
        val words = content.split(" ")
        return words.filter { word ->
            word.isNotEmpty() &&
            word.first().isUpperCase() &&
            word.all { it.isLetter() } &&
            word.length > 1 &&
            !listOf("I", "The", "A", "An", "He", "She", "It", "We", "They", "Had", "Was", "Is", "Are", "Need").contains(word)
        }.distinct()
    }

    private fun extractLocation(content: String): String? {
        return when {
            content.contains("downtown", ignoreCase = true) -> "Downtown"
            content.contains("office", ignoreCase = true) -> "Office"
            content.contains("restaurant", ignoreCase = true) -> "Restaurant"
            content.contains("cafe", ignoreCase = true) -> "Cafe"
            else -> null
        }
    }

    private fun extractAmount(content: String): Double? {
        val regex = Regex("""\$?(\d+(?:,\d{3})*(?:\.\d{2})?)\s*(?:dollars?)?""", RegexOption.IGNORE_CASE)
        return regex.find(content)?.groupValues?.get(1)?.replace(",", "")?.toDoubleOrNull()
    }

    private fun extractEventDate(content: String): String? {
        return when {
            content.contains("next month", ignoreCase = true) -> "Next month"
            content.contains("next week", ignoreCase = true) -> "Next week"
            content.contains("tomorrow", ignoreCase = true) -> "Tomorrow"
            else -> null
        }
    }

    private fun determineCategory(content: String): String {
        return when {
            content.contains("wedding", ignoreCase = true) ||
            content.contains("birthday", ignoreCase = true) ||
            content.contains("anniversary", ignoreCase = true) -> "Event"

            content.contains("meeting", ignoreCase = true) ||
            content.contains("call", ignoreCase = true) -> "Meeting"

            content.contains("pay", ignoreCase = true) ||
            content.contains("dollars", ignoreCase = true) ||
            content.contains("money", ignoreCase = true) -> "Financial"

            content.contains("promise", ignoreCase = true) ||
            content.contains("need to", ignoreCase = true) -> "Promise"

            else -> "General"
        }
    }

    private fun generateReminderSuggestion(content: String): String? {
        return when {
            content.contains("wedding", ignoreCase = true) -> "Remind you before the wedding?"
            content.contains("birthday", ignoreCase = true) -> "Set birthday reminder?"
            content.contains("meeting", ignoreCase = true) -> "Add meeting to calendar?"
            else -> null
        }
    }
}

data class RecordUiState(
    val recordState: RecordState = RecordState.VOICE_IDLE,
    val recordingTime: String = "0:00",
    val transcription: String = "",
    val textContent: String = "",
    val audioLevel: Float = 0f,
    val aiResult: AIAnalysisResult? = null,
    val error: String? = null
)

enum class RecordState {
    VOICE_IDLE,
    VOICE_RECORDING,
    TEXT_MODE,
    AI_PROCESSING,
    AI_RESULT
}

data class AIAnalysisResult(
    val content: String,
    val people: List<String> = emptyList(),
    val newPersonDetected: Boolean = false,
    val location: String? = null,
    val event: String? = null,
    val eventDate: String? = null,
    val amount: String? = null,
    val amountLabel: String? = null,
    val category: String = "General",
    val suggestedReminder: String? = null
)
