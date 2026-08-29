package com.clearguardalliance.clearguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

class PackageInstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_PACKAGE_ADDED) return
        if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return

        val packageName = intent.data?.schemeSpecificPart ?: return
        if (!WATCHED_PACKAGES.contains(packageName)) return

        val appLabel = try {
            val info = context.packageManager.getApplicationInfo(packageName, 0)
            context.packageManager.getApplicationLabel(info).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName
        }

        NativeWebhookNotifier.notify(
            context,
            "Um app de VPN/anonimato foi instalado neste dispositivo: $appLabel. " +
                "Isso pode ser usado para tentar contornar a proteção do ClearGuard.",
        )
    }

    companion object {
        private val WATCHED_PACKAGES = setOf(
            "com.nordvpn.android",
            "com.expressvpn.vpn",
            "ch.protonvpn.android",
            "com.psiphon3",
            "com.windscribe.vpn",
            "org.torproject.torbrowser",
            "org.torproject.android",
        )
    }
}
