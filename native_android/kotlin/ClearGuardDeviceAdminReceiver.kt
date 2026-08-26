package com.clearguardalliance.clearguard

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

/**
 * Registers ClearGuard as a device administrator. This does not add a hard
 * technical barrier. Android always lets the device owner deactivate any
 * admin app from Settings > Security > Device admin apps, and no
 * non-MDM app can prevent that. What this buys is friction and honesty:
 * uninstalling requires a deliberate detour through system settings first,
 * it can't happen with one tap from the launcher, and [onDisableRequested]
 * is a hook where a future version could notify the accountability partner
 * the moment deactivation is attempted, before it completes.
 */
class ClearGuardDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Desativar o administrador do ClearGuard permite desinstalar o " +
            "app. Considere pedir ao seu parceiro de accountability antes."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(context, "Administrador do ClearGuard desativado", Toast.LENGTH_LONG).show()
    }
}
