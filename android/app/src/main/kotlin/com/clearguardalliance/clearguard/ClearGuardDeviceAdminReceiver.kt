package com.clearguardalliance.clearguard

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ClearGuardDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        NativeWebhookNotifier.notify(
            context,
            "Alguém tentou desativar o administrador do ClearGuard neste " +
                "dispositivo às $time. Isso é o primeiro passo pra conseguir " +
                "desinstalar o app.",
        )
        return "Desativar o administrador do ClearGuard permite desinstalar o " +
            "app. Considere pedir ao seu parceiro de accountability antes."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(context, "Administrador do ClearGuard desativado", Toast.LENGTH_LONG).show()
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        NativeWebhookNotifier.notify(
            context,
            "O administrador do ClearGuard foi desativado neste dispositivo " +
                "às $time. O app agora pode ser desinstalado normalmente.",
        )
    }
}
