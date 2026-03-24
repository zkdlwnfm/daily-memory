package com.dailymemory.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_preferences")

@Singleton
class UserPreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val USER_NAME = stringPreferencesKey("user_name")
        val IS_ONBOARDED = booleanPreferencesKey("is_onboarded")
        val THEME_MODE = stringPreferencesKey("theme_mode") // "system", "light", "dark"
        val NOTIFICATIONS_ENABLED = booleanPreferencesKey("notifications_enabled")
        val BIOMETRIC_ENABLED = booleanPreferencesKey("biometric_enabled")
        val AUTO_SAVE_ENABLED = booleanPreferencesKey("auto_save_enabled")
        val LAST_SYNC_TIME = stringPreferencesKey("last_sync_time")
    }

    // User Name
    val userName: Flow<String> = context.dataStore.data.map { preferences ->
        preferences[Keys.USER_NAME] ?: "User"
    }

    suspend fun setUserName(name: String) {
        context.dataStore.edit { preferences ->
            preferences[Keys.USER_NAME] = name
        }
    }

    // Onboarding
    val isOnboarded: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[Keys.IS_ONBOARDED] ?: false
    }

    suspend fun setOnboarded(value: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.IS_ONBOARDED] = value
        }
    }

    // Theme
    val themeMode: Flow<String> = context.dataStore.data.map { preferences ->
        preferences[Keys.THEME_MODE] ?: "system"
    }

    suspend fun setThemeMode(mode: String) {
        context.dataStore.edit { preferences ->
            preferences[Keys.THEME_MODE] = mode
        }
    }

    // Notifications
    val notificationsEnabled: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[Keys.NOTIFICATIONS_ENABLED] ?: true
    }

    suspend fun setNotificationsEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.NOTIFICATIONS_ENABLED] = enabled
        }
    }

    // Biometric
    val biometricEnabled: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[Keys.BIOMETRIC_ENABLED] ?: false
    }

    suspend fun setBiometricEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.BIOMETRIC_ENABLED] = enabled
        }
    }

    // Auto Save
    val autoSaveEnabled: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[Keys.AUTO_SAVE_ENABLED] ?: true
    }

    suspend fun setAutoSaveEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.AUTO_SAVE_ENABLED] = enabled
        }
    }

    // Last Sync Time
    val lastSyncTime: Flow<String?> = context.dataStore.data.map { preferences ->
        preferences[Keys.LAST_SYNC_TIME]
    }

    suspend fun setLastSyncTime(time: String) {
        context.dataStore.edit { preferences ->
            preferences[Keys.LAST_SYNC_TIME] = time
        }
    }

    // Clear all preferences
    suspend fun clearAll() {
        context.dataStore.edit { preferences ->
            preferences.clear()
        }
    }
}
