package hacker.silverwolf.punklorde

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.net.VpnService
import android.content.ComponentName
import android.content.ServiceConnection
import android.os.IBinder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    companion object {
        private const val VPN_PREPARE_REQUEST = 24
    }

    private val WIDGET_CHANNEL = "hacker.silverwolf.punklorde/widget_refresh"
    private val PKLD_CHANNEL = "hacker.silverwolf.punklorde/pkld_handler"
    private val VPN_CHANNEL = "hacker.silverwolf.punklorde/vpn"
    private var pendingPkldBytes: ByteArray? = null
    private var flutterEngine: FlutterEngine? = null
    private var vpnFdReadyCallback: (() -> Unit)? = null

    // Store pending VPN params while waiting for user to grant permission
    private var pendingVpnParams: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "forceRefresh") {
                MainScope().launch {
                    try {
                        ScheduleAppWidget().updateAll(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("REFRESH_ERROR", e.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PKLD_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPendingPkldFile") {
                val bytes = pendingPkldBytes
                pendingPkldBytes = null
                result.success(bytes)
            } else {
                result.notImplemented()
            }
        }

        // VPN channel
        setupVpnChannel(flutterEngine)

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return

        val uri = intent?.data ?: return
        val bytes = readBytesFromUri(uri)
        if (bytes != null) {
            pendingPkldBytes = bytes
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, PKLD_CHANNEL).invokeMethod("onPkldFileReceived", bytes)
            }
        }
    }

    private fun readBytesFromUri(uri: Uri): ByteArray? {
        return try {
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (e: Exception) {
            null
        }
    }

    // ── VPN ──

    private fun setupVpnChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Set up callback: when VpnService establishes the interface, notify Flutter
        SangforVpnService.onVpnReady = { fd ->
            channel.invokeMethod("onVpnReady", fd)
        }

        SangforVpnService.onVpnStopped = {
            channel.invokeMethod("onVpnStopped", null)
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val params = mapOf(
                        "address" to (call.argument<String>("address") ?: "10.8.0.2"),
                        "netmask" to (call.argument<String>("netmask") ?: "255.255.255.0"),
                        "dns" to (call.argument<String>("dns") ?: "114.114.114.114,223.5.5.5"),
                        "mtu" to (call.argument<Int>("mtu") ?: 1400),
                        "routes" to (call.argument<String>("routes") ?: "0.0.0.0/0")
                    )

                    // Check if VPN is already prepared (user has granted permission)
                    val prepareIntent = VpnService.prepare(this)
                    if (prepareIntent != null) {
                        // Not prepared yet - show system dialog to request permission
                        pendingVpnParams = params
                        startActivityForResult(prepareIntent, VPN_PREPARE_REQUEST)
                        result.success("preparing") // permissions are requested by system
                    } else {
                        // Already prepared - start VPN directly
                        doStartVpn(params)
                        result.success(true)
                    }
                }
                "stopVpn" -> {
                    stopVpnService()
                    result.success(true)
                }
                "getVpnFd" -> {
                    val fd = SangforVpnService.currentFd
                    result.success(if (fd > 0) fd else null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun doStartVpn(params: Map<String, Any>) {
        startVpnService(
            params["address"] as String,
            params["netmask"] as String,
            params["dns"] as String,
            params["mtu"] as Int,
            params["routes"] as String
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PREPARE_REQUEST) {
            val params = pendingVpnParams
            pendingVpnParams = null
            if (resultCode == Activity.RESULT_OK && params != null) {
                doStartVpn(params)
            }
        }
    }

    private fun startVpnService(
        address: String,
        netmask: String,
        dns: String,
        mtu: Int,
        routes: String
    ) {
        val intent = Intent(this, SangforVpnService::class.java).apply {
            action = SangforVpnService.ACTION_START_VPN
            putExtra(SangforVpnService.EXTRA_ADDRESS, address)
            putExtra(SangforVpnService.EXTRA_NETMASK, netmask)
            putExtra(SangforVpnService.EXTRA_DNS, dns)
            putExtra(SangforVpnService.EXTRA_MTU, mtu)
            putExtra(SangforVpnService.EXTRA_ROUTES, routes)
        }
        startService(intent)
    }

    private fun stopVpnService() {
        val intent = Intent(this, SangforVpnService::class.java).apply {
            action = SangforVpnService.ACTION_STOP_VPN
        }
        startService(intent)
    }
}