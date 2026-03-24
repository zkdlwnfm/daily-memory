package com.dailymemory.presentation.settings

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    // TODO: Inject use cases
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    fun toggleReminders(enabled: Boolean) {
        _uiState.update { it.copy(remindersEnabled = enabled) }
    }

    fun toggleDailyPrompt(enabled: Boolean) {
        _uiState.update { it.copy(dailyPromptEnabled = enabled) }
    }

    fun toggleOnThisDay(enabled: Boolean) {
        _uiState.update { it.copy(onThisDayEnabled = enabled) }
    }

    fun toggleAppLock(enabled: Boolean) {
        _uiState.update { it.copy(appLockEnabled = enabled) }
    }

    fun toggleShowLockedMemories(enabled: Boolean) {
        _uiState.update { it.copy(showLockedMemories = enabled) }
    }

    fun toggleAutoAnalyze(enabled: Boolean) {
        _uiState.update { it.copy(autoAnalyzeEnabled = enabled) }
    }

    fun toggleSmartReminders(enabled: Boolean) {
        _uiState.update { it.copy(smartRemindersEnabled = enabled) }
    }

    fun syncNow() {
        _uiState.update { it.copy(lastSyncTime = "Just now") }
    }

    fun signOut() {
        // TODO: Implement sign out
    }
}

data class SettingsUiState(
    // Account
    val userEmail: String = "alex@email.com",
    val isPremium: Boolean = true,

    // Sync
    val lastSyncTime: String = "Just now",

    // Notifications
    val remindersEnabled: Boolean = true,
    val dailyPromptEnabled: Boolean = true,
    val dailyPromptTime: String = "9 PM",
    val quietHoursStart: String = "10 PM",
    val quietHoursEnd: String = "9 AM",
    val onThisDayEnabled: Boolean = true,

    // Privacy
    val appLockEnabled: Boolean = true,
    val showLockedMemories: Boolean = false,

    // AI
    val autoAnalyzeEnabled: Boolean = true,
    val smartRemindersEnabled: Boolean = true,

    // App Info
    val appVersion: String = "1.0.0"
)
