package com.clearguardalliance.clearguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!BlockerVpnService.wasActiveBeforeShutdown(context)) return

        val domains = BlockerVpnService.persistedDomains(context)
        BlockerVpnService.start(context, domains)
    }
}
