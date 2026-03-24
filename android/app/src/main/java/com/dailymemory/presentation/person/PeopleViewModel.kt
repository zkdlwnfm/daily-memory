package com.dailymemory.presentation.person

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.usecase.memory.SearchMemoriesUseCase
import com.dailymemory.domain.usecase.person.DeletePersonUseCase
import com.dailymemory.domain.usecase.person.GetAllPersonsUseCase
import com.dailymemory.domain.usecase.person.GetPersonUseCase
import com.dailymemory.domain.usecase.person.SavePersonUseCase
import com.dailymemory.domain.usecase.person.UpdatePersonUseCase
import com.dailymemory.domain.usecase.reminder.GetUpcomingRemindersUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import javax.inject.Inject

@HiltViewModel
class PeopleViewModel @Inject constructor(
    private val getAllPersonsUseCase: GetAllPersonsUseCase,
    private val getPersonUseCase: GetPersonUseCase,
    private val savePersonUseCase: SavePersonUseCase,
    private val updatePersonUseCase: UpdatePersonUseCase,
    private val deletePersonUseCase: DeletePersonUseCase,
    private val searchMemoriesUseCase: SearchMemoriesUseCase,
    private val getUpcomingRemindersUseCase: GetUpcomingRemindersUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(PeopleUiState())
    val uiState: StateFlow<PeopleUiState> = _uiState.asStateFlow()

    init {
        loadPeople()
    }

    private fun loadPeople() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            getAllPersonsUseCase()
                .catch { e ->
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message
                    )}
                }
                .collect { persons ->
                    // Get upcoming reminders for each person
                    val upcomingReminders = try {
                        getUpcomingRemindersUseCase(limit = 20).first()
                    } catch (e: Exception) {
                        emptyList()
                    }

                    val displayItems = persons.map { person ->
                        val personReminders = upcomingReminders.filter { it.personId == person.id }
                        person.toDisplayItem(personReminders.firstOrNull()?.title)
                    }

                    _uiState.update { it.copy(
                        people = persons,
                        filteredPeople = sortPeople(persons, it.sortOrder),
                        displayItems = displayItems,
                        isLoading = false
                    )}
                }
        }
    }

    fun updateSearchQuery(query: String) {
        _uiState.update { state ->
            val filtered = if (query.isBlank()) {
                state.people
            } else {
                state.people.filter {
                    it.name.contains(query, ignoreCase = true) ||
                    it.nickname?.contains(query, ignoreCase = true) == true
                }
            }
            state.copy(
                searchQuery = query,
                filteredPeople = sortPeople(filtered, state.sortOrder)
            )
        }
    }

    fun updateSortOrder(sortOrder: SortOrder) {
        _uiState.update { state ->
            state.copy(
                sortOrder = sortOrder,
                filteredPeople = sortPeople(state.filteredPeople, sortOrder)
            )
        }
    }

    private fun sortPeople(people: List<Person>, sortOrder: SortOrder): List<Person> {
        return when (sortOrder) {
            SortOrder.RECENT -> people.sortedByDescending { it.lastMeetingDate }
            SortOrder.ALPHABETICAL -> people.sortedBy { it.name }
            SortOrder.FREQUENT -> people.sortedByDescending { it.meetingCount }
        }
    }

    fun getPersonById(personId: String): Person? {
        return _uiState.value.people.find { it.id == personId }
    }

    suspend fun getPersonByIdAsync(personId: String): Person? {
        return getPersonUseCase(personId)
    }

    fun savePerson(person: Person) {
        viewModelScope.launch {
            savePersonUseCase(person)
                .onSuccess {
                    loadPeople() // Refresh the list
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message) }
                }
        }
    }

    fun updatePerson(person: Person) {
        viewModelScope.launch {
            updatePersonUseCase(person)
                .onSuccess {
                    loadPeople() // Refresh the list
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message) }
                }
        }
    }

    fun deletePerson(personId: String) {
        viewModelScope.launch {
            deletePersonUseCase(personId)
                .onSuccess {
                    loadPeople() // Refresh the list
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message) }
                }
        }
    }

    suspend fun getMemoriesForPerson(personId: String): Int {
        return try {
            searchMemoriesUseCase.byPerson(personId).first().size
        } catch (e: Exception) {
            0
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun refresh() {
        loadPeople()
    }
}

data class PeopleUiState(
    val people: List<Person> = emptyList(),
    val filteredPeople: List<Person> = emptyList(),
    val displayItems: List<PersonDisplayItem> = emptyList(),
    val searchQuery: String = "",
    val sortOrder: SortOrder = SortOrder.RECENT,
    val isLoading: Boolean = true,
    val error: String? = null
)

enum class SortOrder {
    RECENT,
    ALPHABETICAL,
    FREQUENT
}

// UI Models for display
data class PersonDisplayItem(
    val person: Person,
    val daysAgo: Long,
    val hasUpcomingEvent: Boolean = false,
    val upcomingEventLabel: String? = null,
    val hasNoContactWarning: Boolean = false,
    val noContactDays: Long = 0
)

fun Person.toDisplayItem(upcomingEventLabel: String? = null): PersonDisplayItem {
    val daysAgo = lastMeetingDate?.let {
        ChronoUnit.DAYS.between(it, LocalDateTime.now())
    } ?: 0

    val noContactWarning = daysAgo > 30

    return PersonDisplayItem(
        person = this,
        daysAgo = daysAgo,
        hasUpcomingEvent = upcomingEventLabel != null,
        upcomingEventLabel = upcomingEventLabel,
        hasNoContactWarning = noContactWarning,
        noContactDays = daysAgo
    )
}
