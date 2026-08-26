package com.clearguardalliance.clearguard

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Fallback content layer, complementing BlockerVpnService's DNS-level
 * blocking. DNS filtering only stops a domain from resolving in the first
 * place; this catches explicit content that got past that (an
 * already-cached DNS entry, a raw-IP link, a search results page, text
 * inside an otherwise-unblocked site) by scanning the visible text on
 * screen for keyword matches and covering the screen when one hits.
 *
 * This is a keyword heuristic over text nodes, not an image classifier.
 * It will not catch a page that is explicit content with no matching text
 * (e.g. an image with no surrounding label). See README.md for the v2 plan
 * to add on-device NSFW image classification.
 */
class ScreenContentMonitorService : AccessibilityService() {

    private var keywords: Set<String> = emptySet()
    private var lastTriggeredAtMs = 0L

    private val preferenceListener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
        if (key == KEYWORDS_KEY) {
            keywords = prefs.getStringSet(KEYWORDS_KEY, DEFAULT_KEYWORDS) ?: DEFAULT_KEYWORDS
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 300
        }
        keywords = loadKeywords(this)
        prefs(this).registerOnSharedPreferenceChangeListener(preferenceListener)
    }

    override fun onUnbind(intent: Intent?): Boolean {
        prefs(this).unregisterOnSharedPreferenceChangeListener(preferenceListener)
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val now = System.currentTimeMillis()
        if (now - lastTriggeredAtMs < TRIGGER_COOLDOWN_MS) return
        if (keywords.isEmpty()) return

        val root = rootInActiveWindow ?: return
        val budget = NodeBudget(MAX_NODES_PER_SCAN)
        val matched = containsBlockedKeyword(root, budget)

        if (matched) {
            lastTriggeredAtMs = now
            launchOverlay()
        }
    }

    private fun containsBlockedKeyword(node: AccessibilityNodeInfo, budget: NodeBudget): Boolean {
        if (!budget.consume()) return false

        val text = node.text?.toString()?.lowercase()
        if (text != null && keywords.any { text.contains(it) }) return true

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (containsBlockedKeyword(child, budget)) return true
        }
        return false
    }

    private fun launchOverlay() {
        val intent = Intent(this, BlockOverlayActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(intent)
    }

    override fun onInterrupt() = Unit

    /** Caps how many nodes a single scan walks, so a deeply nested or huge
     * screen (an endless web page, a chat log) can't stall the
     * accessibility event thread. */
    private class NodeBudget(private var remaining: Int) {
        fun consume(): Boolean {
            if (remaining <= 0) return false
            remaining -= 1
            return true
        }
    }

    companion object {
        private const val PREFS_NAME = "clearguard_screen_monitor"
        private const val KEYWORDS_KEY = "keywords"
        private const val TRIGGER_COOLDOWN_MS = 2000L
        private const val MAX_NODES_PER_SCAN = 400

        private val DEFAULT_KEYWORDS = setOf(
            "porn", "pornô", "porno", "xvideos", "xnxx", "nudes", "sexo explícito",
        )

        fun updateKeywords(context: Context, keywords: List<String>) {
            val effective = if (keywords.isEmpty()) DEFAULT_KEYWORDS else keywords.map { it.lowercase() }.toSet()
            prefs(context).edit().putStringSet(KEYWORDS_KEY, effective).apply()
        }

        private fun loadKeywords(context: Context): Set<String> {
            return prefs(context).getStringSet(KEYWORDS_KEY, DEFAULT_KEYWORDS) ?: DEFAULT_KEYWORDS
        }

        private fun prefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }
}
