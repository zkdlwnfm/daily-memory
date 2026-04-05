package com.dailymemory.presentation.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.usecase.memory.SearchMemoriesUseCase
import com.dailymemory.domain.usecase.person.GetAllPersonsUseCase
import com.dailymemory.domain.usecase.search.SemanticSearchUseCase
import com.dailymemory.domain.usecase.search.SemanticSearchResult
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
    private val getAllPersonsUseCase: GetAllPersonsUseCase,
    private val semanticSearchUseCase: SemanticSearchUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private val _availablePersons = MutableStateFlow<List<Person>>(emptyList())
    val availablePersons: StateFlow<List<Person>> = _availablePersons.asStateFlow()

    private var isSemanticSearchEnabled = true

    init {
        loadRecentSearches()
        loadAvailablePersons()
        indexMemoriesIfNeeded()
    }

    private fun indexMemoriesIfNeeded() {
        viewModelScope.launch {
            val indexedCount = semanticSearchUseCase.indexAllUnindexed()
            if (indexedCount > 0) {
                // Memories indexed for semantic search
            }
        }
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
            if (isSemanticSearchEnabled) {
                performSemanticSearch(query)
            } else {
                performKeywordSearch(query)
            }
        }
    }

    private suspend fun performSemanticSearch(query: String) {
        semanticSearchUseCase.searchHybrid(query, 20)
            .onSuccess { searchResults ->
                val filter = _uiState.value.advancedFilter
                val filteredResults = searchResults.filter { result ->
                    applyFilter(result.memory, filter)
                }

                if (filteredResults.isEmpty()) {
                    _uiState.update { it.copy(
                        searchState = SearchState.EMPTY,
                        filteredMemories = emptyList(),
                        aiResponse = null
                    )}
                } else {
                    val memories = filteredResults.map { it.memory }
                    val aiResponse = generateSemanticAIResponse(query, filteredResults)

                    _uiState.update { it.copy(
                        searchState = SearchState.RESULT,
                        filteredMemories = memories,
                        aiResponse = aiResponse,
                        recentSearches = if (query.isNotBlank()) {
                            listOf(query) + it.recentSearches.filter { s -> s != query }.take(4)
                        } else it.recentSearches
                    )}
                }
            }
            .onFailure {
                // Fallback to keyword search
                performKeywordSearch(query)
            }
    }

    private suspend fun performKeywordSearch(query: String) {
        try {
            val memories = searchMemoriesUseCase(query).first()
            val filter = _uiState.value.advancedFilter
            val filteredMemories = memories.filter { memory ->
                applyFilter(memory, filter)
            }

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

    private fun generateSemanticAIResponse(query: String, results: List<SemanticSearchResult>): AIResponse {
        val relatedMemories = results.take(5).map { result ->
            RelatedMemory(
                id = result.memory.id,
                date = result.memory.recordedAt,
                content = result.memory.content,
                tags = buildList {
                    result.memory.extractedPersons.forEach { add(MemoryTag("person", it)) }
                    result.memory.extractedLocation?.let { add(MemoryTag("location", it)) }
                    add(MemoryTag("similarity", "${result.similarityPercent}% match"))
                }
            )
        }

        val mainAnswer = generateSemanticAnswer(query, results)
        val details = results.firstOrNull()?.let { first ->
            "Most relevant (${first.similarityPercent}% match): ${first.memory.content.take(100)}..."
        }

        return AIResponse(
            mainAnswer = mainAnswer,
            details = details,
            highlight = results.firstOrNull()?.let { "Best match: ${it.similarityPercent}% relevance" },
            relatedMemories = relatedMemories,
            followUpQuestions = generateFollowUpQuestions(query, results.map { it.memory })
        )
    }

    private fun generateSemanticAnswer(query: String, results: List<SemanticSearchResult>): String {
        val queryLower = query.lowercase()

        if (queryLower.contains("when")) {
            results.firstOrNull()?.let { first ->
                return "Based on your memories, this happened on ${first.memory.recordedAt.format(DateTimeFormatter.ofPattern("MMMM d, yyyy"))}."
            }
        }

        if (queryLower.contains("who")) {
            val allPersons = results.flatMap { it.memory.extractedPersons }.distinct()
            if (allPersons.isNotEmpty()) {
                return "People mentioned: ${allPersons.joinToString(", ")}."
            }
        }

        if (queryLower.contains("where")) {
            val allLocations = results.mapNotNull { it.memory.extractedLocation }.distinct()
            if (allLocations.isNotEmpty()) {
                return "Locations found: ${allLocations.joinToString(", ")}."
            }
        }

        if (queryLower.contains("how much") || queryLower.contains("money")) {
            val amounts = results.mapNotNull { it.memory.extractedAmount }
            if (amounts.isNotEmpty()) {
                val total = amounts.sum()
                return "Total amount mentioned: $${String.format("%.2f", total)}."
            }
        }

        return "Found ${results.size} relevant memories matching your question."
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
