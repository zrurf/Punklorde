package hacker.silverwolf.punklorde

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

/**
 * Android VPN Service for Sangfor SSL VPN.
 *
 * This service creates a TUN interface via VpnService.Builder.establish()
 * and provides the file descriptor to Rust for bidirectional packet relay.
 */
class SangforVpnService : VpnService() {

    companion object {
        const val TAG = "SangforVpnService"
        const val CHANNEL_ID = "sangfor_vpn_channel"
        const val NOTIFICATION_ID = 3001
        const val NOTIFICATION_ID_CONNECTED = 3002

        // Intent actions
        const val ACTION_START_VPN = "hacker.silverwolf.punklorde.START_VPN"
        const val ACTION_STOP_VPN = "hacker.silverwolf.punklorde.STOP_VPN"

        // Intent extras
        const val EXTRA_ADDRESS = "vpn_address"
        const val EXTRA_NETMASK = "vpn_netmask"
        const val EXTRA_DNS = "vpn_dns"
        const val EXTRA_MTU = "vpn_mtu"
        const val EXTRA_ROUTES = "vpn_routes"

        // VPN configuration passed from Flutter
        var vpnAddress: String = "10.8.0.2"
        var vpnNetmask: String = "255.255.255.0"
        var vpnDnsServers: String = "114.114.114.114,223.5.5.5"
        var vpnMtu: Int = 1400
        var vpnRoutes: String = "" // comma-separated CIDR, e.g. "0.0.0.0/0"
        var vpnAppPackage: String = "" // empty = all traffic through VPN

        // The established fd, to be picked up by Rust
        var established: Boolean = false
        var currentFd: Int = -1

        // Hold a reference to the ParcelFileDescriptor so it can be explicitly closed
        // when the VPN is stopped. If GC collects it, the underlying fd may be closed
        // prematurely or the VPN interface may not be properly torn down.
        var vpnPfd: ParcelFileDescriptor? = null

        // Callback: called when the VPN fd is ready
        var onVpnReady: ((Int) -> Unit)? = null
        var onVpnStopped: (() -> Unit)? = null
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "SangforVpnService created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")

        when (intent?.action) {
            ACTION_START_VPN -> {
                val address = intent.getStringExtra(EXTRA_ADDRESS) ?: vpnAddress
                val netmask = intent.getStringExtra(EXTRA_NETMASK) ?: vpnNetmask
                val dnsStr = intent.getStringExtra(EXTRA_DNS) ?: vpnDnsServers
                val mtu = intent.getIntExtra(EXTRA_MTU, vpnMtu)
                val routesStr = intent.getStringExtra(EXTRA_ROUTES) ?: vpnRoutes

                vpnAddress = address
                vpnNetmask = netmask
                vpnDnsServers = dnsStr
                vpnMtu = mtu
                vpnRoutes = routesStr

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        NOTIFICATION_ID,
                        buildForegroundNotification("Connecting VPN..."),
                        android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                } else {
                    startForeground(NOTIFICATION_ID, buildForegroundNotification("Connecting VPN..."))
                }
                establishVpn()
            }
            ACTION_STOP_VPN -> {
                stopVpn()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }

        return START_NOT_STICKY
    }

    /**
     * Build the VPN interface using VpnService.Builder and establish it.
     * After establishment, the fd is passed to the onVpnReady callback.
     */
    private fun establishVpn() {
        Log.d(TAG, "establishVpn: configuring...")

        try {
            val builder = Builder()

            // Set interface address
            val parts = vpnNetmask.split(".")
            val prefixLen = if (parts.size == 4) {
                var mask = 0L
                for (i in 0 until 4) {
                    mask = (mask shl 8) or parts[i].toLong()
                }
                mask.countOneBits()
            } else {
                24
            }
            builder.setSession(getString(R.string.app_name))
            builder.addAddress(vpnAddress, prefixLen)

            // Configure routes
            if (vpnRoutes.isNotBlank()) {
                for (route in vpnRoutes.split(",")) {
                    val trimmed = route.trim()
                    if (trimmed.isNotEmpty()) {
                        val routeParts = trimmed.split("/")
                        if (routeParts.size == 2) {
                            builder.addRoute(routeParts[0].trim(), routeParts[1].trim().toInt())
                        } else {
                            builder.addRoute(trimmed, 32)
                        }
                    }
                }
            } else {
                // Default: route all traffic through VPN
                builder.addRoute("0.0.0.0", 0)
            }

            // Configure DNS servers
            if (vpnDnsServers.isNotBlank()) {
                for (dns in vpnDnsServers.split(",")) {
                    val trimmed = dns.trim()
                    if (trimmed.isNotEmpty()) {
                        builder.addDnsServer(trimmed)
                    }
                }
            }

            // Filter apps (empty = all apps)
            if (vpnAppPackage.isNotBlank()) {
                builder.addAllowedApplication(vpnAppPackage)
            }

            // Disable VPN for this app itself to prevent routing loops
            try {
                builder.addDisallowedApplication(packageName)
            } catch (_: Exception) {
                // Ignored
            }

            // MTU
            builder.setMtu(vpnMtu)

            // Do NOT route IPv6 through VPN — the campus VPN is IPv4-only.
            // Routing IPv6 (e.g. via addRoute("::", 0)) would send all IPv6
            // traffic (incl. Android connectivity probes) through the TUN,
            // where it would be dropped, causing the system to mark the
            // network as disconnected and send zero IPv4 traffic.

            // Establish the VPN interface
            Log.d(TAG, "establishVpn: calling establish()...")
            val pfd: ParcelFileDescriptor = builder.establish()
                ?: throw IllegalStateException("VpnService.Builder.establish() returned null")

            vpnPfd = pfd
            val fd = pfd.fd
            currentFd = fd
            established = true

            Log.d(TAG, "VPN established! fd=$fd")

            // Update notification
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildForegroundNotification("VPN Connected"))

            // Notify Rust via callback
            onVpnReady?.invoke(fd)

        } catch (e: Exception) {
            Log.e(TAG, "establishVpn failed: ${e.message}", e)
            stopVpn()
            stopSelf()
        }
    }

    /**
     * Stop the VPN and release resources.
     */
    private fun stopVpn() {
        Log.d(TAG, "stopVpn")
        established = false
        currentFd = -1
        try {
            vpnPfd?.close()
            Log.d(TAG, "VPN ParcelFileDescriptor closed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to close VPN fd: ${e.message}")
        }
        vpnPfd = null
        onVpnStopped?.invoke()
    }

    override fun onDestroy() {
        Log.d(TAG, "SangforVpnService destroyed")
        stopVpn()
        super.onDestroy()
    }

    override fun onRevoke() {
        Log.d(TAG, "VPN revoked by user")
        stopVpn()
        super.onRevoke()
    }

    // ── Notification ──

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "VPN connection status"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(statusText: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, SangforVpnService::class.java).apply {
            action = ACTION_STOP_VPN
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle(getString(R.string.app_name))
                .setContentText(statusText)
                .setSmallIcon(android.R.drawable.ic_menu_share)
                .setOngoing(true)
                .setContentIntent(pendingIntent)
                .addAction(android.R.drawable.ic_media_pause, "Disconnect", stopPendingIntent)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle(getString(R.string.app_name))
                .setContentText(statusText)
                .setSmallIcon(android.R.drawable.ic_menu_share)
                .setOngoing(true)
                .setContentIntent(pendingIntent)
                .build()
        }
    }

    }