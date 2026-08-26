package com.clearguardalliance.clearguard

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class ClearGuardDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Desativar o administrador do ClearGuard permite desinstalar o " +
            "app. Considere pedir ao seu parceiro de accountability antes."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(context, "Administrador do ClearGuard desativado", Toast.LENGTH_LONG).show()
    }
}
