package com.clearguardalliance.clearguard

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import java.util.Calendar

class TriggerAppGuardService : AccessibilityService() {
    private var triggerPackages: Set<String> = emptySet()
    private var windowEnabled = false
    private var windowStartMinutes = DEFAULT_WINDOW_START
    private var windowEndMinutes = DEFAULT_WINDOW_END
    private var lastPauseAtMs = 0L

    private val preferenceListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, _ -> loadConfig() }

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        loadConfig()
        prefs(this).registerOnSharedPreferenceChangeListener(preferenceListener)
    }

    override fun onUnbind(intent: Intent?): Boolean {
        prefs(this).unregisterOnSharedPreferenceChangeListener(preferenceListener)
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return
        if (packageName !in triggerPackages) return
        if (!FeatureFlags.isAccessibilityGuardEnabled(this)) return

        if (isWithinBlockWindow()) {
            launchGuard(TriggerAppGuardActivity.MODE_BLOCK)
            return
        }

        val now = System.currentTimeMillis()
        if (now - lastPauseAtMs < PAUSE_COOLDOWN_MS) return
        lastPauseAtMs = now
        launchGuard(TriggerAppGuardActivity.MODE_PAUSE)
    }

    private fun isWithinBlockWindow(): Boolean {
        if (!windowEnabled) return false
        val calendar = Calendar.getInstance()
        val minutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        return if (windowStartMinutes <= windowEndMinutes) {
            minutes in windowStartMinutes until windowEndMinutes
        } else {
            minutes >= windowStartMinutes || minutes < windowEndMinutes
        }
    }

    private fun launchGuard(mode: String) {
        val intent = Intent(this, TriggerAppGuardActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(TriggerAppGuardActivity.EXTRA_MODE, mode)
        startActivity(intent)
    }

    private fun loadConfig() {
        val p = prefs(this)
        triggerPackages = p.getStringSet(PACKAGES_KEY, emptySet()) ?: emptySet()
        windowEnabled = p.getBoolean(WINDOW_ENABLED_KEY, false)
        windowStartMinutes = p.getInt(WINDOW_START_KEY, DEFAULT_WINDOW_START)
        windowEndMinutes = p.getInt(WINDOW_END_KEY, DEFAULT_WINDOW_END)
    }

    override fun onInterrupt() = Unit

    companion object {
        private const val PREFS_NAME = "clearguard_trigger_guard"
        private const val PACKAGES_KEY = "packages"
        private const val WINDOW_ENABLED_KEY = "window_enabled"
        private const val WINDOW_START_KEY = "window_start"
        private const val WINDOW_END_KEY = "window_end"
        private const val PAUSE_COOLDOWN_MS = 5000L
        private const val DEFAULT_WINDOW_START = 23 * 60
        private const val DEFAULT_WINDOW_END = 6 * 60

        fun syncConfig(
            context: Context,
            packages: List<String>,
            windowEnabled: Boolean,
            windowStartMinutes: Int,
            windowEndMinutes: Int,
        ) {
            prefs(context).edit()
                .putStringSet(PACKAGES_KEY, packages.toSet())
                .putBoolean(WINDOW_ENABLED_KEY, windowEnabled)
                .putInt(WINDOW_START_KEY, windowStartMinutes)
                .putInt(WINDOW_END_KEY, windowEndMinutes)
                .apply()
        }

        private fun prefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }
}
