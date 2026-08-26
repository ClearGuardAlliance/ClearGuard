package com.clearguardalliance.clearguard

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Composition root on the native side: wires the three platform channels the
 * Dart layer talks to (VPN control, VPN status stream, screen-monitor
 * control) to their Android implementations. Business logic itself lives in
 * BlockerVpnService and ScreenContentMonitorService. This class is only
 * plumbing.
 */
class MainActivity : FlutterActivity() {

    private val vpnChannelName = "com.clearguard.app/vpn"
    private val vpnStatusChannelName = "com.clearguard.app/vpn/status"
    private val screenMonitorChannelName = "com.clearguard.app/screen_monitor"

    private var pendingVpnPermissionResult: MethodChannel.Result? = null
    private var vpnStatusEventSink: EventChannel.EventSink? = null

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
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent == null) {
            // Already granted.
            result.success(true)
            return
        }
        pendingVpnPermissionResult = result
        startActivityForResult(prepareIntent, VPN_PERMISSION_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            pendingVpnPermissionResult?.success(resultCode == RESULT_OK)
            pendingVpnPermissionResult = null
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
    }
}
