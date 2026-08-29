package com.clearguardalliance.clearguard

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class SettingsGuardService : AccessibilityService() {
    private var lastRedirectAtMs = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName !in GUARDED_PACKAGES) return

        if (!FeatureFlags.isAccessibilityGuardEnabled(this)) return
        if (!settingsContainsClearGuard()) return

        val now = System.currentTimeMillis()
        if (now - lastRedirectAtMs < REDIRECT_COOLDOWN_MS) return
        lastRedirectAtMs = now

        redirectToMain()
    }

    private fun settingsContainsClearGuard(): Boolean {
        val root = rootInActiveWindow ?: return false
        return root.findAccessibilityNodeInfosByText("ClearGuard").isNotEmpty()
    }

    private fun redirectToMain() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
        startActivity(intent)
    }

    override fun onInterrupt() = Unit

    companion object {
        private const val REDIRECT_COOLDOWN_MS = 500L

        private val GUARDED_PACKAGES = setOf(
            "com.android.settings",
        )
    }
}
