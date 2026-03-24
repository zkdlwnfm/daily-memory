package com.dailymemory.presentation.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.usecase.memory.SearchMemoriesUseCase
import com.dailymemory.domain.usecase.person.GetAllPersonsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val searchMemoriesUseCase: SearchMemoriesUseCase,
    private val getAllPersonsUseCase: GetAllPersonsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private val _availablePersons = MutableStateFlow<List<Person>>(emptyList())
    val availablePersons: StateFlow<List<Person>> = _availablePersons.asStateFlow()

    init {
        loadRecentSearches()
        loadAvailablePersons()
    }

    private fun loadRecentSearches() {
        // TODO: Load from DataStore/preferences
        _uiState.update { it.copy(
            recentSearches = listOf(
                "Mike wedding",
                "Mom birthday gift",
                "Acme meeting"
            )
        )}
    }

    private fun loadAvailablePersons() {
        viewModelScope.launch {
            try {
                _availablePersons.value = getAllPersonsUseCase().first()
            } catch (e: Exception) {
                // Ignore errors during initial load
            }
        }
    }

    fun updateFilter(filter: AdvancedFilter) {
        _uiState.update { it.copy(advancedFilter = filter) }
        // Re-search with new filter if we have a query
        if (_uiState.value.query.isNotBlank() || filter.isActive()) {
            searchWithFilter()
        }
    }

    fun clearFilter() {
        _uiState.update { it.copy(advancedFilter = AdvancedFilter()) }
        if (_uiState.value.query.isNotBlank()) {
            search()
        }
    }

    private fun searchWithFilter() {
        _uiState.update { it.copy(searchState = SearchState.SEARCHING) }

        viewModelScope.launch {
            try {
                val query = _uiState.value.query
                val filter = _uiState.value.advancedFilter

                // Search memories
                val memories = searchMemoriesUseCase(query).first()

                // Apply advanced filters
                val filteredMemories = memories.filter { memory ->
                    applyFilter(memory, filter)
                }

                if (filteredMemories.isEmpty()) {
                    _uiState.update { it.copy(
                        searchState = SearchState.EMPTY,
                        filteredMemories = emptyList()
                    )}
                } else {
                    _uiState.update { it.copy(
                        searchState = SearchState.RESULT,
                        filteredMemories = filteredMemories
                    )}
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(
                    searchState = SearchState.INITIAL,
                    error = e.message
                )}
            }
        }
    }

    private fun applyFilter(memory: Memory, filter: AdvancedFilter): Boolean {
        // Date range filter
        if (filter.startDate != null) {
            val memoryDate = memory.recordedAt.toLocalDate()
            if (memoryDate.isBefore(filter.startDate)) return false
        }
        if (filter.endDate != null) {
            val memoryDate = memory.recordedAt.toLocalDate()
            if (memoryDate.isAfter(filter.endDate)) return false
        }

        // Category filter
        if (filter.categories.isNotEmpty() && !filter.categories.contains(memory.category)) {
            return false
        }

        // Person filter
        if (filter.personIds.isNotEmpty()) {
            val hasMatchingPerson = memory.personIds.any { filter.personIds.contains(it) }
            if (!hasMatchingPerson) return false
        }

        // Amount range filter
        if (filter.minAmount != null && (memory.extractedAmount == null || memory.extractedAmount < filter.minAmount)) {
            return false
        }
        if (filter.maxAmount != null && (memory.extractedAmount == null || memory.extractedAmount > filter.maxAmount)) {
            return false
        }

        // Has photos filter
        if (filter.hasPhotos == true && memory.photos.isEmpty()) {
            return false
        }

        // Is locked filter
        if (filter.isLocked == true && !memory.isLocked) {
            return false
        }

        return true
    }

    fun updateQuery(query: String) {
        _uiState.update { it.copy(query = query) }
    }

    fun search() {
        val query = _uiState.value.query
        if (query.isBlank() && !_uiState.value.advancedFilter.isActive()) return

        _uiState.update { it.copy(searchState = SearchState.SEARCHING) }

        viewModelScope.launch {
            try {
                // Search memories using the use case
                val memories = searchMemoriesUseCase(query).first()

                // Apply advanced filters
                val filter = _uiState.value.advancedFilter
                val filteredMemories = memories.filter { memory ->
                    applyFilter(memory, filter)
                }

                // Generate AI response from results
                val aiResponse = if (filteredMemories.isNotEmpty()) {
                    generateAIResponse(query, filteredMemories)
                } else null

                if (filteredMemories.isEmpty() && aiResponse == null) {
                    _uiState.update { it.copy(
                        searchState = SearchState.EMPTY,
                        filteredMemories = emptyList(),
                        aiResponse = null
                    )}
                } else {
                    _uiState.update { it.copy(
                        searchState = SearchState.RESULT,
                        filteredMemories = filteredMemories,
                        aiResponse = aiResponse,
                        recentSearches = if (query.isNotBlank()) {
                            listOf(query) + it.recentSearches.filter { s -> s != query }.take(4)
                        } else it.recentSearches
                    )}
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(
                    searchState = SearchState.EMPTY,
                    error = e.message
                )}
            }
        }
    }

    private fun generateAIResponse(query: String, memories: List<Memory>): AIResponse {
        // Convert memories to related memories format
        val relatedMemories = memories.take(5).map { memory ->
            RelatedMemory(
                id = memory.id,
                date = memory.recordedAt,
                content = memory.content,
                tags = buildList {
                    memory.extractedPersons.forEach { add(MemoryTag("person", it)) }
                    memory.extractedLocation?.let { add(MemoryTag("location", it)) }
                }
            )
        }

        // Generate summary answer
        val mainAnswer = when {
            memories.size == 1 -> "Found 1 memory matching \"$query\""
            memories.isNotEmpty() -> "Found ${memories.size} memories matching \"$query\""
            else -> "No memories found for \"$query\""
        }

        // Extract common details
        val locations = memories.mapNotNull { it.extractedLocation }.distinct()
        val persons = memories.flatMap { it.extractedPersons }.distinct()
        val totalAmount = memories.mapNotNull { it.extractedAmount }.sum()

        val details = buildString {
            if (persons.isNotEmpty()) {
                append("People mentioned: ${persons.take(3).joinToString(", ")}")
                if (persons.size > 3) append(" and ${persons.size - 3} more")
                append(". ")
            }
            if (locations.isNotEmpty()) {
                append("Locations: ${locations.take(3).joinToString(", ")}. ")
            }
            if (totalAmount > 0) {
                append("Total amount: $${String.format("%.2f", totalAmount)}. ")
            }
        }.takeIf { it.isNotBlank() }

        return AIResponse(
            mainAnswer = mainAnswer,
            details = details,
            highlight = if (memories.isNotEmpty()) {
                "Most recent: ${memories.first().recordedAt.format(DateTimeFormatter.ofPattern("MMM d, yyyy"))}"
            } else null,
            relatedMemories = relatedMemories,
            followUpQuestions = generateFollowUpQuestions(query, memories)
        )
    }

    private fun generateFollowUpQuestions(query: String, memories: List<Memory>): List<String> {
        val questions = mutableListOf<String>()

        // Extract persons for follow-up questions
        val persons = memories.flatMap { it.extractedPersons }.distinct().take(2)
        persons.forEach { person ->
            questions.add("What else did $person mention?")
        }

        // Add time-based questions
        if (memories.isNotEmpty()) {
            questions.add("Show me similar memories from last month")
        }

        return questions.take(3)
    }

    fun selectSuggestion(suggestion: String) {
        _uiState.update { it.copy(query = suggestion) }
        search()
    }

    fun selectRecentSearch(search: String) {
        _uiState.update { it.copy(query = search) }
        search()
    }

    fun removeRecentSearch(search: String) {
        _uiState.update { it.copy(
            recentSearches = it.recentSearches.filter { it != search }
        )}
    }

    fun clearRecentSearches() {
        _uiState.update { it.copy(recentSearches = emptyList()) }
    }

    fun newSearch() {
        _uiState.update { it.copy(
            query = "",
            searchState = SearchState.INITIAL,
            aiResponse = null
        )}
    }

    fun askFollowUp(question: String) {
        _uiState.update { it.copy(query = question) }
        search()
    }
}

data class SearchUiState(
    val query: String = "",
    val searchState: SearchState = SearchState.INITIAL,
    val aiResponse: AIResponse? = null,
    val filteredMemories: List<Memory> = emptyList(),
    val advancedFilter: AdvancedFilter = AdvancedFilter(),
    val recentSearches: List<String> = emptyList(),
    val suggestions: List<Suggestion> = defaultSuggestions,
    val error: String? = null
)

enum class SearchState {
    INITIAL,
    SEARCHING,
    RESULT,
    EMPTY
}

data class AIResponse(
    val mainAnswer: String,
    val details: String? = null,
    val highlight: String? = null,
    val relatedMemories: List<RelatedMemory> = emptyList(),
    val followUpQuestions: List<String> = emptyList()
)

data class RelatedMemory(
    val id: String,
    val date: LocalDateTime,
    val content: String,
    val tags: List<MemoryTag> = emptyList()
) {
    fun formattedDate(): String {
        return date.format(DateTimeFormatter.ofPattern("MMM d, h:mm a"))
    }
}

data class MemoryTag(
    val type: String, // "person", "location", "event"
    val value: String
)

data class Suggestion(
    val text: String,
    val isHighlighted: Boolean = false
)

val defaultSuggestions = listOf(
    Suggestion("When is Mike's wedding?", isHighlighted = true),
    Suggestion("What did I do with Mom last year?"),
    Suggestion("Do I owe anyone money?"),
    Suggestion("Summarize my work meetings this month", isHighlighted = true)
)
