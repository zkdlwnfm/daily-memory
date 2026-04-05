package com.dailymemory.presentation.reminder

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.data.service.GeofenceService
import com.dailymemory.data.service.NotificationService
import com.dailymemory.domain.model.LocationTriggerType
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.model.RepeatType
import com.dailymemory.domain.usecase.memory.GetMemoryUseCase
import com.dailymemory.domain.usecase.person.GetAllPersonsUseCase
import com.dailymemory.domain.usecase.person.GetPersonUseCase
import com.dailymemory.domain.usecase.reminder.SaveReminderUseCase
import com.dailymemory.domain.usecase.reminder.UpdateReminderUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import javax.inject.Inject

@HiltViewModel
class ReminderEditViewModel @Inject constructor(
    private val saveReminderUseCase: SaveReminderUseCase,
    private val updateReminderUseCase: UpdateReminderUseCase,
    private val getMemoryUseCase: GetMemoryUseCase,
    private val getPersonUseCase: GetPersonUseCase,
    private val getAllPersonsUseCase: GetAllPersonsUseCase,
    private val notificationService: NotificationService,
    private val geofenceService: GeofenceService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ReminderEditUiState())
    val uiState: StateFlow<ReminderEditUiState> = _uiState.asStateFlow()

    private var existingReminderId: String? = null
    private var linkedMemoryId: String? = null

    fun initialize(reminderId: String?, memoryId: String?, personId: String?) {
        viewModelScope.launch {
            // Load available persons
            try {
                val persons = getAllPersonsUseCase().first()
                _uiState.update { it.copy(availablePersons = persons) }
            } catch (e: Exception) {
                // Ignore
            }

            // Load existing reminder if editing
            if (reminderId != null) {
                existingReminderId = reminderId
                // TODO: Add GetReminderByIdUseCase and load reminder
            }

            // Load linked memory if provided
            if (memoryId != null) {
                linkedMemoryId = memoryId
                try {
                    getMemoryUseCase(memoryId)?.let { memory ->
                        _uiState.update { it.copy(
                            linkedMemoryPreview = memory.content.take(100)
                        )}
                    }
                } catch (e: Exception) {
                    // Ignore
                }
            }

            // Load linked person if provided
            if (personId != null) {
                try {
                    getPersonUseCase(personId)?.let { person ->
                        _uiState.update { it.copy(linkedPerson = person) }
                    }
                } catch (e: Exception) {
                    // Ignore
                }
            }
        }
    }

    fun updateTitle(title: String) {
        _uiState.update { it.copy(title = title) }
    }

    fun updateBody(body: String) {
        _uiState.update { it.copy(body = body) }
    }

    fun updateDate(date: LocalDate) {
        _uiState.update { it.copy(date = date) }
    }

    fun updateTime(time: LocalTime) {
        _uiState.update { it.copy(time = time) }
    }

    fun updateRepeatType(repeatType: RepeatType) {
        _uiState.update { it.copy(repeatType = repeatType) }
    }

    fun updateLinkedPerson(person: Person?) {
        _uiState.update { it.copy(linkedPerson = person) }
    }

    fun updateIsLocationBased(isLocationBased: Boolean) {
        _uiState.update { it.copy(isLocationBased = isLocationBased) }
    }

    fun updateSelectedLocation(location: SelectedLocation?) {
        _uiState.update { it.copy(selectedLocation = location) }
    }

    fun setQuickTime(hoursFromNow: Int) {
        val now = LocalDateTime.now().plusHours(hoursFromNow.toLong())
        _uiState.update { it.copy(
            date = now.toLocalDate(),
            time = now.toLocalTime()
        )}
    }

    fun setTomorrow() {
        val tomorrow = LocalDate.now().plusDays(1)
        _uiState.update { it.copy(
            date = tomorrow,
            time = LocalTime.of(9, 0) // Default to 9 AM
        )}
    }

    fun setNextWeek() {
        val nextWeek = LocalDate.now().plusWeeks(1)
        _uiState.update { it.copy(
            date = nextWeek,
            time = LocalTime.of(9, 0)
        )}
    }

    fun save() {
        val state = _uiState.value
        if (!state.isValid) return

        _uiState.update { it.copy(isSaving = true) }

        viewModelScope.launch {
            val scheduledAt = LocalDateTime.of(state.date, state.time)

            val reminder = Reminder(
                id = existingReminderId ?: java.util.UUID.randomUUID().toString(),
                memoryId = linkedMemoryId,
                personId = state.linkedPerson?.id,
                title = state.title,
                body = state.body,
                scheduledAt = scheduledAt,
                repeatType = state.repeatType,
                isActive = true,
                isAutoGenerated = false,
                // Location data
                latitude = state.selectedLocation?.latitude,
                longitude = state.selectedLocation?.longitude,
                radius = state.selectedLocation?.radius,
                locationTriggerType = state.selectedLocation?.triggerType,
                locationName = state.selectedLocation?.name
            )

            val result = if (existingReminderId != null) {
                updateReminderUseCase(reminder)
            } else {
                saveReminderUseCase(reminder)
            }

            result
                .onSuccess {
                    if (reminder.isLocationBased) {
                        // Start geofence monitoring
                        geofenceService.startMonitoring(reminder) { success ->
                            if (!success) {
                                // Geofence couldn't be started, but reminder is still saved
                            }
                        }
                    } else {
                        // Schedule time-based notification
                        notificationService.scheduleReminder(reminder)
                    }
                    _uiState.update { it.copy(isSaving = false, saveSuccess = true) }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isSaving = false, error = e.message) }
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class ReminderEditUiState(
    val title: String = "",
    val body: String = "",
    val date: LocalDate = LocalDate.now(),
    val time: LocalTime = LocalTime.now().plusHours(1).withMinute(0),
    val repeatType: RepeatType = RepeatType.NONE,
    val linkedPerson: Person? = null,
    val linkedMemoryPreview: String? = null,
    val availablePersons: List<Person> = emptyList(),
    // Location-based reminder
    val isLocationBased: Boolean = false,
    val selectedLocation: SelectedLocation? = null,
    val isSaving: Boolean = false,
    val saveSuccess: Boolean = false,
    val error: String? = null
) {
    val isValid: Boolean
        get() {
            if (title.isBlank()) return false
            if (isLocationBased && selectedLocation == null) return false
            return true
        }
}
