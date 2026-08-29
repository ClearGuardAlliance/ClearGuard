package com.clearguardalliance.clearguard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ConcurrentHashMap

class BlockerVpnService : VpnService() {
    private var tunInterface: ParcelFileDescriptor? = null
    private val running = AtomicBoolean(false)
    private var workerThread: Thread? = null
    private val forwardExecutor = Executors.newCachedThreadPool()
    private val blockedDomains = ConcurrentHashMap.newKeySet<String>()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                blockedDomains.clear()
                blockedDomains.addAll(intent.getStringArrayListExtra(EXTRA_DOMAINS) ?: arrayListOf())
                startForeground(NOTIFICATION_ID, buildNotification())
                startVpn()
            }
            ACTION_UPDATE_BLOCKLIST -> {
                blockedDomains.clear()
                blockedDomains.addAll(intent.getStringArrayListExtra(EXTRA_DOMAINS) ?: arrayListOf())
            }
            ACTION_STOP -> stopVpn()
        }
        persistState(applicationContext, running.get(), blockedDomains)
        return START_STICKY
    }

    private fun startVpn() {
        if (running.get()) return

        val builder = Builder()
            .setSession("ClearGuard")
            .addAddress(VPN_LOCAL_ADDRESS, 32)
            .addDnsServer(DNS_SERVER_ADDRESS)
            .addRoute(DNS_SERVER_ADDRESS, 32)

        for (resolverIp in BYPASS_RESOLVER_IPS) {
            builder.addRoute(resolverIp, 32)
        }

        val establishedInterface = builder.establish()
        if (establishedInterface == null) {
            broadcastStatus(Status.ERROR)
            return
        }

        tunInterface = establishedInterface
        running.set(true)
        broadcastStatus(Status.ACTIVE)

        workerThread = Thread({ runPacketLoop(establishedInterface) }, "clearguard-dns-loop").apply {
            start()
        }
    }

    private fun stopVpn() {
        running.set(false)
        workerThread?.join(1000)
        workerThread = null
        runCatching { tunInterface?.close() }
        tunInterface = null
        broadcastStatus(Status.DISABLED)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        stopVpn()
        forwardExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun onRevoke() {
        NativeWebhookNotifier.notify(
            this,
            "A permissão de VPN do ClearGuard foi revogada nas configurações " +
                "do sistema neste dispositivo. A proteção parou de funcionar.",
        )
        stopVpn()
        super.onRevoke()
    }

    private fun runPacketLoop(fd: ParcelFileDescriptor) {
        val input = FileInputStream(fd.fileDescriptor)
        val output = FileOutputStream(fd.fileDescriptor)
        val buffer = ByteArray(MAX_PACKET_SIZE)

        while (running.get()) {
            val length = try {
                input.read(buffer)
            } catch (_: Exception) {
                if (running.get()) continue else break
            }
            if (length <= 0) continue

            val packet = buffer.copyOfRange(0, length)
            try {
                handlePacket(packet, output)
            } catch (_: Exception) {
            }
        }
    }

    private fun handlePacket(packet: ByteArray, output: FileOutputStream) {
        val ip = Ipv4Header.parse(packet) ?: return
        if (ip.protocol != PROTOCOL_UDP) return

        val udp = UdpHeader.parse(packet, ip.headerLength) ?: return
        if (udp.destinationPort != DNS_PORT) return

        val dnsStart = ip.headerLength + UdpHeader.LENGTH
        val dnsMessage = packet.copyOfRange(dnsStart, packet.size)
        val query = DnsQuery.parse(dnsMessage) ?: return

        val enforcedHost = SafeSearchPolicy.enforcedHostFor(query.domainName)
        if (enforcedHost != null) {
            forwardExecutor.execute {
                forwardSafeSearchRewrite(dnsMessage, query, enforcedHost, ip, udp, output)
            }
            return
        }

        if (isBlocked(query.domainName)) {
            val response = DnsResponses.sinkhole(dnsMessage, query)
            writeUdpPacket(
                output = output,
                sourceAddress = ip.destinationAddress,
                sourcePort = udp.destinationPort,
                destinationAddress = ip.sourceAddress,
                destinationPort = udp.sourcePort,
                payload = response,
            )
            return
        }

        forwardExecutor.execute {
            forwardToUpstream(dnsMessage, ip, udp, output)
        }
    }

    private fun isBlocked(domain: String): Boolean {
        if (isBlockedBySuffix(domain)) return true
        val proxiedTarget = TranslateProxyHost.decodeTargetHost(domain) ?: return false
        return isBlockedBySuffix(proxiedTarget)
    }

    private fun isBlockedBySuffix(domain: String): Boolean {
        var candidate = domain
        while (true) {
            if (blockedDomains.contains(candidate)) return true
            val dot = candidate.indexOf('.')
            if (dot < 0) return false
            candidate = candidate.substring(dot + 1)
        }
    }

    private fun forwardToUpstream(
        dnsMessage: ByteArray,
        ip: Ipv4Header,
        udp: UdpHeader,
        output: FileOutputStream,
    ) {
        for (server in UPSTREAM_DNS_SERVERS) {
            val responseBytes = queryUpstream(dnsMessage, server) ?: continue
            writeUdpPacket(
                output = output,
                sourceAddress = ip.destinationAddress,
                sourcePort = udp.destinationPort,
                destinationAddress = ip.sourceAddress,
                destinationPort = udp.sourcePort,
                payload = responseBytes,
            )
            return
        }
    }

    private fun forwardSafeSearchRewrite(
        dnsMessage: ByteArray,
        query: DnsQuery,
        enforcedHost: String,
        ip: Ipv4Header,
        udp: UdpHeader,
        output: FileOutputStream,
    ) {
        val originalQuestion = dnsMessage.copyOfRange(12, query.questionEndOffset)
        val rewrittenQuery = SafeSearchRewriter.buildUpstreamQuery(dnsMessage, query, enforcedHost)
        val rewrittenQuestionLength = SafeSearchRewriter.rewrittenQuestionLength(query, enforcedHost)

        for (server in UPSTREAM_DNS_SERVERS) {
            val raw = queryUpstream(rewrittenQuery, server) ?: continue
            val response = SafeSearchRewriter.restoreOriginalName(
                raw,
                originalQuestion,
                rewrittenQuestionLength,
            ) ?: continue
            writeUdpPacket(
                output = output,
                sourceAddress = ip.destinationAddress,
                sourcePort = udp.destinationPort,
                destinationAddress = ip.sourceAddress,
                destinationPort = udp.sourcePort,
                payload = response,
            )
            return
        }
    }

    private fun queryUpstream(dnsMessage: ByteArray, server: String): ByteArray? {
        return try {
            DatagramSocket().use { socket ->
                protect(socket)
                socket.soTimeout = UPSTREAM_TIMEOUT_MS
                val upstream = InetSocketAddress(InetAddress.getByName(server), DNS_PORT)
                socket.send(DatagramPacket(dnsMessage, dnsMessage.size, upstream))

                val responseBuffer = ByteArray(MAX_PACKET_SIZE)
                val responsePacket = DatagramPacket(responseBuffer, responseBuffer.size)
                socket.receive(responsePacket)
                responsePacket.data.copyOfRange(0, responsePacket.length)
            }
        } catch (_: Exception) {
            null
        }
    }

    @Synchronized
    private fun writeUdpPacket(
        output: FileOutputStream,
        sourceAddress: ByteArray,
        sourcePort: Int,
        destinationAddress: ByteArray,
        destinationPort: Int,
        payload: ByteArray,
    ) {
        val packet = PacketBuilder.buildIpv4Udp(
            sourceAddress = sourceAddress,
            sourcePort = sourcePort,
            destinationAddress = destinationAddress,
            destinationPort = destinationPort,
            payload = payload,
        )
        output.write(packet)
    }

    private fun broadcastStatus(status: Status) {
        currentStatus = status
        val intent = Intent(ACTION_STATUS_CHANGED)
            .setPackage(packageName)
            .putExtra(EXTRA_STATUS, status.name.lowercase())
        sendBroadcast(intent)
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "ClearGuard protection",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }

        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("ClearGuard protection is active")
            .setContentText("Filtering blocked domains")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .build()
    }

    enum class Status { STARTING, ACTIVE, DISABLED, ERROR }

    companion object {
        const val ACTION_START = "com.clearguard.app.vpn.START"
        const val ACTION_STOP = "com.clearguard.app.vpn.STOP"
        const val ACTION_UPDATE_BLOCKLIST = "com.clearguard.app.vpn.UPDATE_BLOCKLIST"
        const val ACTION_STATUS_CHANGED = "com.clearguard.app.vpn.STATUS_CHANGED"
        const val EXTRA_DOMAINS = "domains"
        const val EXTRA_STATUS = "status"

        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL_ID = "clearguard_vpn"
        private const val MAX_PACKET_SIZE = 32767
        private const val DNS_PORT = 53
        private const val PROTOCOL_UDP = 17
        private const val UPSTREAM_TIMEOUT_MS = 5000
        private const val VPN_LOCAL_ADDRESS = "10.111.222.1"
        private const val DNS_SERVER_ADDRESS = "10.111.222.2"

        private val UPSTREAM_DNS_SERVERS = listOf("208.67.222.123", "208.67.220.123")

        // Public DNS resolvers commonly used for DNS-over-HTTPS/TLS, which would
        // otherwise let a browser bypass the filter above by not using the system
        // resolver at all. Routing their IPs into the tunnel means any non-DNS
        // (i.e. DoH/DoT) traffic to them hits handlePacket and gets silently
        // dropped, forcing a fallback to plain DNS on port 53, which is filtered.
        private val BYPASS_RESOLVER_IPS = listOf(
            "1.1.1.1",
            "1.0.0.1",
            "8.8.8.8",
            "8.8.4.4",
            "9.9.9.9",
            "149.112.112.112",
            "208.67.222.222",
            "208.67.220.220",
            "94.140.14.14",
            "94.140.15.15",
            "185.222.222.222",
            "45.11.45.11",
        )

        @Volatile
        var currentStatus: Status = Status.DISABLED
            private set

        fun start(context: Context, domains: List<String>) {
            val intent = Intent(context, BlockerVpnService::class.java)
                .setAction(ACTION_START)
                .putStringArrayListExtra(EXTRA_DOMAINS, ArrayList(domains))
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.startService(Intent(context, BlockerVpnService::class.java).setAction(ACTION_STOP))
        }

        fun updateBlocklist(context: Context, domains: List<String>) {
            val intent = Intent(context, BlockerVpnService::class.java)
                .setAction(ACTION_UPDATE_BLOCKLIST)
                .putStringArrayListExtra(EXTRA_DOMAINS, ArrayList(domains))
            context.startService(intent)
        }

        fun wasActiveBeforeShutdown(context: Context): Boolean {
            return statePrefs(context).getBoolean(KEY_ACTIVE, false)
        }

        fun persistedDomains(context: Context): List<String> {
            return statePrefs(context).getStringSet(KEY_DOMAINS, emptySet())?.toList() ?: emptyList()
        }

        private fun persistState(context: Context, active: Boolean, domains: Collection<String>) {
            statePrefs(context).edit()
                .putBoolean(KEY_ACTIVE, active)
                .putStringSet(KEY_DOMAINS, domains.toSet())
                .apply()
        }

        private fun statePrefs(context: Context) =
            context.getSharedPreferences("clearguard_vpn_state", Context.MODE_PRIVATE)

        private const val KEY_ACTIVE = "active"
        private const val KEY_DOMAINS = "domains"
    }
}
