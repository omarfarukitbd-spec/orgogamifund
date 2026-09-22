package com.helptrickbd.myapplicationsomithierp.core.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "shomiti_user_preferences")

enum class AppThemeMode {
    SYSTEM, LIGHT, DARK
}

enum class AppLanguage(val code: String) {
    ENGLISH("en"), BANGLA("bn")
}

data class UserPreferences(
    val language: AppLanguage = AppLanguage.BANGLA,
    val themeMode: AppThemeMode = AppThemeMode.SYSTEM,
    val isBiometricEnabled: Boolean = false,
    val isOnboardingCompleted: Boolean = false
)

class UserPreferencesRepository(private val context: Context) {

    private object PreferencesKeys {
        val LANGUAGE = stringPreferencesKey("app_language")
        val THEME_MODE = stringPreferencesKey("app_theme_mode")
        val BIOMETRIC_ENABLED = booleanPreferencesKey("is_biometric_enabled")
        val ONBOARDING_COMPLETED = booleanPreferencesKey("is_onboarding_completed")
    }

    val userPreferencesFlow: Flow<UserPreferences> = context.dataStore.data
        .map { preferences ->
            val langCode = preferences[PreferencesKeys.LANGUAGE] ?: AppLanguage.BANGLA.code
            val language = if (langCode == AppLanguage.ENGLISH.code) AppLanguage.ENGLISH else AppLanguage.BANGLA

            val themeName = preferences[PreferencesKeys.THEME_MODE] ?: AppThemeMode.SYSTEM.name
            val themeMode = try {
                AppThemeMode.valueOf(themeName)
            } catch (e: Exception) {
                AppThemeMode.SYSTEM
            }

            val biometric = preferences[PreferencesKeys.BIOMETRIC_ENABLED] ?: false
            val onboarding = preferences[PreferencesKeys.ONBOARDING_COMPLETED] ?: false

            UserPreferences(
                language = language,
                themeMode = themeMode,
                isBiometricEnabled = biometric,
                isOnboardingCompleted = onboarding
            )
        }

    suspend fun setLanguage(language: AppLanguage) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.LANGUAGE] = language.code
        }
    }

    suspend fun setThemeMode(themeMode: AppThemeMode) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.THEME_MODE] = themeMode.name
        }
    }

    suspend fun setBiometricEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.BIOMETRIC_ENABLED] = enabled
        }
    }

    suspend fun setOnboardingCompleted(completed: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.ONBOARDING_COMPLETED] = completed
        }
    }
}
