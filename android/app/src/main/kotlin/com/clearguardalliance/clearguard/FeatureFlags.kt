package com.clearguardalliance.clearguard

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import io.flutter.plugins.sharedpreferences.sharedPreferencesDataStore
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking

object FeatureFlags {
    fun isAccessibilityGuardEnabled(context: Context): Boolean {
        return try {
            val key = booleanPreferencesKey("flutter.accessibility_features_enabled")
            runBlocking {
                context.sharedPreferencesDataStore.data.map { it[key] }.firstOrNull()
            } ?: true
        } catch (_: Exception) {
            true
        }
    }
}
