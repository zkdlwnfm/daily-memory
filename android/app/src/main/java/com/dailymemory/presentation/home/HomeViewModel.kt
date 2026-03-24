package com.dailymemory.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.usecase.memory.GetRecentMemoriesUseCase
import com.dailymemory.domain.usecase.memory.SearchMemoriesUseCase
import com.dailymemory.domain.usecase.reminder.CompleteReminderUseCase
import com.dailymemory.domain.usecase.reminder.GetTodayRemindersUseCase
import com.dailymemory.domain.usecase.reminder.SnoozeReminderUseCase
import com.dailymemory.data.local.UserPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecentMemoriesUseCase: GetRecentMemoriesUseCase,
    private val getTodayRemindersUseCase: GetTodayRemindersUseCase,
    private val completeReminderUseCase: CompleteReminderUseCase,
    private val snoozeReminderUseCase: SnoozeReminderUseCase,
    private val searchMemoriesUseCase: SearchMemoriesUseCase,
    private val userPreferences: UserPreferences
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadHomeData()
    }

    private fun loadHomeData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // Get user name from preferences
            val userName = userPreferences.userName.first()

            // Combine memories and reminders flows
            combine(
                getRecentMemoriesUseCase(limit = 5),
                getTodayRemindersUseCase()
            ) { memories, reminders ->
                Pair(memories, reminders)
            }
            .catch { e ->
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message
                )
            }
            .collect { (memories, reminders) ->
                val todayMemoryCount = memories.count {
                    it.recordedAt.toLocalDate() == LocalDateTime.now().toLocalDate()
                }

                // Get first active reminder
                val firstReminder = reminders.firstOrNull { it.isActive && it.triggeredAt == null }

                // Load flashback (memories from 1 year ago)
                val flashback = loadFlashback()

                _uiState.value = HomeUiState(
                    isLoading = false,
                    userName = userName,
                    todayMemoryCount = todayMemoryCount,
                    reminderCount = reminders.size,
                    reminder = firstReminder?.toReminderUi(),
                    recentMemories = memories.map { it.toMemoryUi() },
                    flashback = flashback,
                    error = null
                )
            }
        }
    }

    private suspend fun loadFlashback(): FlashbackUi? {
        // Search for memories from 1 year ago (±3 days)
        val oneYearAgo = LocalDateTime.now().minusYears(1)
        val startDate = oneYearAgo.minusDays(3)
        val endDate = oneYearAgo.plusDays(3)

        return try {
            var flashbackMemory: Memory? = null
            searchMemoriesUseCase.byDateRange(startDate, endDate)
                .catch { /* ignore errors */ }
                .collect { memories ->
                    flashbackMemory = memories.firstOrNull { it.photos.isNotEmpty() }
                        ?: memories.firstOrNull()
                }
            flashbackMemory?.toFlashbackUi()
        } catch (e: Exception) {
            null
        }
    }

    fun onReminderDone(reminderId: String) {
        viewModelScope.launch {
            completeReminderUseCase(reminderId)
                .onSuccess {
                    // Remove reminder from UI
                    _uiState.value = _uiState.value.copy(reminder = null)
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(error = e.message)
                }
        }
    }

    fun onReminderSnooze(reminderId: String, minutes: Int = 30) {
        viewModelScope.launch {
            snoozeReminderUseCase(reminderId, minutes)
                .onSuccess {
                    // Remove reminder from UI (will reappear later)
                    _uiState.value = _uiState.value.copy(reminder = null)
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(error = e.message)
                }
        }
    }

    fun refresh() {
        loadHomeData()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}

// Extension functions for mapping domain models to UI models
private fun Memory.toMemoryUi(): MemoryUi {
    val formatter = DateTimeFormatter.ofPattern("h:mm a")
    val daysDiff = ChronoUnit.DAYS.between(recordedAt.toLocalDate(), LocalDateTime.now().toLocalDate())

    val formattedDate = when {
        daysDiff == 0L -> "Today, ${recordedAt.format(formatter)}"
        daysDiff == 1L -> "Yesterday, ${recordedAt.format(formatter)}"
        daysDiff < 7 -> "${daysDiff} days ago"
        else -> recordedAt.format(DateTimeFormatter.ofPattern("MMM d, yyyy"))
    }

    val tags = mutableListOf<TagUi>()
    extractedPersons.forEach { tags.add(TagUi(TagType.PERSON, it)) }
    extractedLocation?.let { tags.add(TagUi(TagType.LOCATION, it)) }
    extractedAmount?.let { tags.add(TagUi(TagType.FINANCIAL, "$$it")) }

    return MemoryUi(
        id = id,
        content = content,
        formattedDate = formattedDate,
        tags = tags
    )
}

private fun Memory.toFlashbackUi(): FlashbackUi {
    val dateFormatter = DateTimeFormatter.ofPattern("MMMM d, yyyy")
    return FlashbackUi(
        id = id,
        title = content.take(50) + if (content.length > 50) "..." else "",
        date = recordedAt.format(dateFormatter),
        imageUrl = photos.firstOrNull()?.url
    )
}

private fun Reminder.toReminderUi(): ReminderUi {
    val type = when {
        personId != null -> ReminderType.BIRTHDAY
        title.contains("meeting", ignoreCase = true) -> ReminderType.MEETING
        title.contains("payment", ignoreCase = true) ||
            title.contains("money", ignoreCase = true) -> ReminderType.FINANCIAL
        else -> ReminderType.GENERAL
    }

    return ReminderUi(
        id = id,
        title = title,
        description = body,
        type = type
    )
}

data class HomeUiState(
    val isLoading: Boolean = false,
    val userName: String = "",
    val todayMemoryCount: Int = 0,
    val reminderCount: Int = 0,
    val reminder: ReminderUi? = null,
    val recentMemories: List<MemoryUi> = emptyList(),
    val flashback: FlashbackUi? = null,
    val error: String? = null
)

data class ReminderUi(
    val id: String,
    val title: String,
    val description: String,
    val type: ReminderType
)

enum class ReminderType {
    BIRTHDAY,
    EVENT,
    MEETING,
    FINANCIAL,
    GENERAL
}

data class MemoryUi(
    val id: String,
    val content: String,
    val formattedDate: String,
    val tags: List<TagUi>
)

data class TagUi(
    val type: TagType,
    val label: String
)

enum class TagType {
    PERSON,
    LOCATION,
    FINANCIAL,
    EVENT,
    GENERAL
}

data class FlashbackUi(
    val id: String,
    val title: String,
    val date: String,
    val imageUrl: String?
)
