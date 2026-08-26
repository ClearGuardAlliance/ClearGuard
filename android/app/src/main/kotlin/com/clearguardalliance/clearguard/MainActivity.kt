package com.clearguardalliance.clearguard

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.net.VpnService
import android.os.PowerManager
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val vpnChannelName = "com.clearguard.app/vpn"
    private val vpnStatusChannelName = "com.clearguard.app/vpn/status"
    private val screenMonitorChannelName = "com.clearguard.app/screen_monitor"
    private val deviceAdminChannelName = "com.clearguard.app/device_admin"

    private var pendingVpnPermissionResult: MethodChannel.Result? = null
    private var pendingDeviceAdminResult: MethodChannel.Result? = null
    private var pendingBatteryOptimizationResult: MethodChannel.Result? = null
    private var vpnStatusEventSink: EventChannel.EventSink? = null

    private val deviceAdminComponent: ComponentName
        get() = ComponentName(this, ClearGuardDeviceAdminReceiver::class.java)

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val status = intent.getStringExtra(BlockerVpnService.EXTRA_STATUS) ?: return
            vpnStatusEventSink?.success(status)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, vpnChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestVpnPermission(result)
                    "start" -> {
                        @Suppress("UNCHECKED_CAST")
                        val domains = (call.argument<List<String>>("domains") ?: emptyList())
                        BlockerVpnService.start(this, domains)
                        result.success(null)
                    }
                    "stop" -> {
                        BlockerVpnService.stop(this)
                        result.success(null)
                    }
                    "updateBlocklist" -> {
                        @Suppress("UNCHECKED_CAST")
                        val domains = (call.argument<List<String>>("domains") ?: emptyList())
                        BlockerVpnService.updateBlocklist(this, domains)
                        result.success(null)
                    }
                    "currentStatus" -> result.success(BlockerVpnService.currentStatus.name.lowercase())
                    "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                    "requestIgnoreBatteryOptimizations" -> requestIgnoreBatteryOptimizations(result)
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, vpnStatusChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    vpnStatusEventSink = events
                    val filter = IntentFilter(BlockerVpnService.ACTION_STATUS_CHANGED)
                    ContextCompat.registerReceiver(
                        this@MainActivity,
                        statusReceiver,
                        filter,
                        ContextCompat.RECEIVER_NOT_EXPORTED,
                    )
                }

                override fun onCancel(arguments: Any?) {
                    vpnStatusEventSink = null
                    runCatching { unregisterReceiver(statusReceiver) }
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenMonitorChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissionGranted" -> result.success(isAccessibilityServiceEnabled())
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "updateKeywords" -> {
                        @Suppress("UNCHECKED_CAST")
                        val keywords = (call.argument<List<String>>("keywords") ?: emptyList())
                        ScreenContentMonitorService.updateKeywords(this, keywords)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceAdminChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isActive" -> result.success(isDeviceAdminActive())
                    "requestActivation" -> requestDeviceAdminActivation(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun isDeviceAdminActive(): Boolean {
        val manager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        return manager.isAdminActive(deviceAdminComponent)
    }

    private fun requestDeviceAdminActivation(result: MethodChannel.Result) {
        if (isDeviceAdminActive()) {
            result.success(true)
            return
        }
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            .putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, deviceAdminComponent)
            .putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Torna a desinstalação do ClearGuard um passo deliberado, " +
                    "em vez de um toque só a partir da tela inicial.",
            )
        pendingDeviceAdminResult = result
        startActivityForResult(intent, DEVICE_ADMIN_REQUEST_CODE)
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return manager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations(result: MethodChannel.Result) {
        if (isIgnoringBatteryOptimizations()) {
            result.success(true)
            return
        }
        val intent = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:$packageName"),
        )
        pendingBatteryOptimizationResult = result
        startActivityForResult(intent, BATTERY_OPTIMIZATION_REQUEST_CODE)
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent == null) {
            result.success(true)
            return
        }
        pendingVpnPermissionResult = result
        startActivityForResult(prepareIntent, VPN_PERMISSION_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            VPN_PERMISSION_REQUEST_CODE -> {
                pendingVpnPermissionResult?.success(resultCode == RESULT_OK)
                pendingVpnPermissionResult = null
            }
            DEVICE_ADMIN_REQUEST_CODE -> {
                pendingDeviceAdminResult?.success(isDeviceAdminActive())
                pendingDeviceAdminResult = null
            }
            BATTERY_OPTIMIZATION_REQUEST_CODE -> {
                pendingBatteryOptimizationResult?.success(isIgnoringBatteryOptimizations())
                pendingBatteryOptimizationResult = null
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val manager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = manager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK,
        )
        return enabledServices.any { it.resolveInfo.serviceInfo.packageName == packageName }
    }

    companion object {
        private const val VPN_PERMISSION_REQUEST_CODE = 4242
        private const val DEVICE_ADMIN_REQUEST_CODE = 4243
        private const val BATTERY_OPTIMIZATION_REQUEST_CODE = 4244
    }
}
