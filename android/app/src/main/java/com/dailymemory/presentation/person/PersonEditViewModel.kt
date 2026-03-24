package com.dailymemory.presentation.person

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.usecase.person.GetPersonUseCase
import com.dailymemory.domain.usecase.person.SavePersonUseCase
import com.dailymemory.domain.usecase.person.UpdatePersonUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import javax.inject.Inject

data class PersonEditUiState(
    val isEditing: Boolean = false,
    val personId: String? = null,
    val name: String = "",
    val nickname: String = "",
    val relationship: Relationship = Relationship.FRIEND,
    val phone: String = "",
    val email: String = "",
    val memo: String = "",
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val saveSuccess: Boolean = false,
    val error: String? = null,
    val nameError: String? = null
)

@HiltViewModel
class PersonEditViewModel @Inject constructor(
    private val getPersonUseCase: GetPersonUseCase,
    private val savePersonUseCase: SavePersonUseCase,
    private val updatePersonUseCase: UpdatePersonUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(PersonEditUiState())
    val uiState: StateFlow<PersonEditUiState> = _uiState.asStateFlow()

    fun loadPerson(personId: String?) {
        if (personId == null) {
            _uiState.update { it.copy(isEditing = false, isLoading = false) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, isEditing = true, personId = personId) }
            try {
                val person = getPersonUseCase(personId)
                if (person != null) {
                    _uiState.update {
                        it.copy(
                            name = person.name,
                            nickname = person.nickname ?: "",
                            relationship = person.relationship,
                            phone = person.phone ?: "",
                            email = person.email ?: "",
                            memo = person.memo ?: "",
                            isLoading = false
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(isLoading = false, error = "Person not found")
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = e.message ?: "Failed to load person")
                }
            }
        }
    }

    fun updateName(name: String) {
        _uiState.update {
            it.copy(
                name = name,
                nameError = if (name.isBlank()) "Name is required" else null
            )
        }
    }

    fun updateNickname(nickname: String) {
        _uiState.update { it.copy(nickname = nickname) }
    }

    fun updateRelationship(relationship: Relationship) {
        _uiState.update { it.copy(relationship = relationship) }
    }

    fun updatePhone(phone: String) {
        _uiState.update { it.copy(phone = phone) }
    }

    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email) }
    }

    fun updateMemo(memo: String) {
        _uiState.update { it.copy(memo = memo) }
    }

    fun save() {
        val state = _uiState.value

        // Validate
        if (state.name.isBlank()) {
            _uiState.update { it.copy(nameError = "Name is required") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            val person = Person(
                id = state.personId ?: java.util.UUID.randomUUID().toString(),
                name = state.name.trim(),
                nickname = state.nickname.takeIf { it.isNotBlank() },
                relationship = state.relationship,
                phone = state.phone.takeIf { it.isNotBlank() },
                email = state.email.takeIf { it.isNotBlank() },
                memo = state.memo.takeIf { it.isNotBlank() },
                createdAt = if (state.isEditing) LocalDateTime.now() else LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )

            val result = if (state.isEditing) {
                updatePersonUseCase(person)
            } else {
                savePersonUseCase(person)
            }

            result
                .onSuccess {
                    _uiState.update { it.copy(isSaving = false, saveSuccess = true) }
                }
                .onFailure { e ->
                    _uiState.update {
                        it.copy(isSaving = false, error = e.message ?: "Failed to save")
                    }
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
