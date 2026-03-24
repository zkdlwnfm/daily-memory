package com.dailymemory.presentation.memory

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.usecase.memory.DeleteMemoryUseCase
import com.dailymemory.domain.usecase.memory.GetMemoryUseCase
import com.dailymemory.domain.usecase.memory.UpdateMemoryUseCase
import com.dailymemory.domain.usecase.person.GetPersonUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MemoryDetailUiState(
    val memory: Memory? = null,
    val linkedPersons: List<Person> = emptyList(),
    val isLoading: Boolean = true,
    val isDeleting: Boolean = false,
    val error: String? = null,
    val deleteSuccess: Boolean = false,
    val showDeleteDialog: Boolean = false
)

@HiltViewModel
class MemoryDetailViewModel @Inject constructor(
    private val getMemoryUseCase: GetMemoryUseCase,
    private val deleteMemoryUseCase: DeleteMemoryUseCase,
    private val updateMemoryUseCase: UpdateMemoryUseCase,
    private val getPersonUseCase: GetPersonUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(MemoryDetailUiState())
    val uiState: StateFlow<MemoryDetailUiState> = _uiState.asStateFlow()

    fun loadMemory(memoryId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val memory = getMemoryUseCase(memoryId)
                if (memory != null) {
                    // Load linked persons
                    val persons = memory.personIds.mapNotNull { personId ->
                        getPersonUseCase(personId)
                    }
                    _uiState.update {
                        it.copy(
                            memory = memory,
                            linkedPersons = persons,
                            isLoading = false
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = "Memory not found"
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load memory"
                    )
                }
            }
        }
    }

    fun showDeleteDialog() {
        _uiState.update { it.copy(showDeleteDialog = true) }
    }

    fun hideDeleteDialog() {
        _uiState.update { it.copy(showDeleteDialog = false) }
    }

    fun deleteMemory() {
        val memory = _uiState.value.memory ?: return
        viewModelScope.launch {
            _uiState.update { it.copy(isDeleting = true, showDeleteDialog = false) }
            deleteMemoryUseCase(memory.id)
                .onSuccess {
                    _uiState.update { it.copy(isDeleting = false, deleteSuccess = true) }
                }
                .onFailure { e ->
                    _uiState.update {
                        it.copy(
                            isDeleting = false,
                            error = e.message ?: "Failed to delete memory"
                        )
                    }
                }
        }
    }

    fun updateCategory(category: Category) {
        val memory = _uiState.value.memory ?: return
        viewModelScope.launch {
            try {
                val updatedMemory = memory.copy(category = category)
                updateMemoryUseCase(updatedMemory)
                _uiState.update { it.copy(memory = updatedMemory) }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message ?: "Failed to update category")
                }
            }
        }
    }

    fun updateImportance(importance: Int) {
        val memory = _uiState.value.memory ?: return
        viewModelScope.launch {
            try {
                val updatedMemory = memory.copy(importance = importance.coerceIn(1, 5))
                updateMemoryUseCase(updatedMemory)
                _uiState.update { it.copy(memory = updatedMemory) }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message ?: "Failed to update importance")
                }
            }
        }
    }

    fun toggleLock() {
        val memory = _uiState.value.memory ?: return
        viewModelScope.launch {
            try {
                val updatedMemory = memory.copy(isLocked = !memory.isLocked)
                updateMemoryUseCase(updatedMemory)
                _uiState.update { it.copy(memory = updatedMemory) }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message ?: "Failed to toggle lock")
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
