import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/vpn/sangfor/background_task.dart';
import 'package:punklorde/module/feature/vpn/sangfor/controller.dart';
import 'package:punklorde/module/feature/vpn/sangfor/data.dart';
import 'package:punklorde/module/feature/vpn/sangfor/view/config_section.dart';
import 'package:punklorde/module/feature/vpn/sangfor/view/console_widget.dart';
import 'package:punklorde/module/feature/vpn/sangfor/view/status_widget.dart';
import 'package:punklorde/module/feature/vpn/sangfor/view/traffic_widget.dart';
import 'package:punklorde/src/rust/services/sangfor.dart'
    hide VpnTrafficStats; // Use local VpnTrafficStats from data.dart
import 'package:signals/signals_flutter.dart';

class FeatSangforVpnView extends StatefulWidget {
  final String? defaultServer;

  const FeatSangforVpnView({super.key, this.defaultServer});

  @override
  State<FeatSangforVpnView> createState() => _FeatSangforVpnViewState();
}

class _FeatSangforVpnViewState extends State<FeatSangforVpnView> {
  static const _vpnChannelName = 'hacker.silverwolf.punklorde/vpn';

  final SangforVpnController _controller = SangforVpnController();
  StreamSubscription<VpnState>? _stateSub;
  final _twoFaController = TextEditingController();
  bool _showTwoFa = false;
  bool _isTotp = false;
  Timer? _trafficTimer;

  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpSecretController = TextEditingController();
  final _dnsController = TextEditingController();

  MethodChannel? _vpnChannel;
  Completer<int>? _vpnFdCompleter;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _setupVpnChannel();
  }

  void _setupVpnChannel() {
    _vpnChannel = const MethodChannel(_vpnChannelName);
    _vpnChannel?.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onVpnReady':
          final fd = call.arguments as int;
          _controller.setupAndroidTun(fd);
          _vpnFdCompleter?.complete(fd);
          break;
        case 'onVpnStopped':
          _vpnFdCompleter = null;
          break;
      }
    });
  }

  void _loadConfig() {
    final config = vpnConfig.value;
    final defaultServer = widget.defaultServer;

    _serverController.text = config.server.isNotEmpty
        ? config.server
        : (defaultServer ?? '');
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _totpSecretController.text = config.totpSecret;
    _dnsController.text = config.customDns ?? '';
  }

  void _saveConfig() {
    vpnConfig.value = VpnConfigData(
      server: _serverController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      totpSecret: _totpSecretController.text,
      customDns: _dnsController.text.isEmpty ? null : _dnsController.text,
      splitRoutes: '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
    );
  }

  VpnConfig _buildRustConfig() {
    final c = vpnConfig.value;
    return VpnConfig(
      server: _normalizeServer(c.server),
      username: c.username,
      password: c.password,
      totpSecret: c.totpSecret,
      customDns: c.customDns,
      tunAddress: '10.0.0.2',
      tunNetmask: '255.255.255.0',
      mtu: 1500,
      splitRoutes: c.splitRoutes,
    );
  }

  /// Normalize server address: strip protocol prefix, add default port 443
  String _normalizeServer(String server) {
    var s = server.trim();
    s = s.replaceFirst(RegExp(r'^[Hh][Tt][Tt][Pp][Ss]?://'), '');
    if (!s.contains(':')) {
      s = '$s:443';
    }
    return s;
  }

  Future<void> _connect() async {
    _saveConfig();

    if (vpnConfig.value.server.isEmpty || vpnConfig.value.username.isEmpty) {
      _showError(t.submodule.sangfor_vpn.fill_server_username);
      return;
    }

    addVpnLog(VpnLogLevel.info, 'Connecting to ${vpnConfig.value.server}...');
    vpnLogs.value = []; // Clear logs for new connection
    vpnTraffic.value = .zero;
    vpnShowConsole.value = false; // Reset console state

    try {
      vpnStatus.value = VpnStatusData(state: VpnConnectionState.connecting);
      vpnIsRunning.value = true;

      final rustConfig = _buildRustConfig();
      _controller.create(rustConfig);

      final stream = await _controller.subscribe();
      _stateSub = stream.listen(
        _onStateChange,
        onError: (e) {
          _showError(e.toString());
          _cleanupAfterError();
        },
      );

      // Phase 1: Authenticate and get server-assigned IP
      try {
        _controller.authenticateAndGetIp();
      } catch (e) {
        if (e.toString().contains('SMS_REQUIRED') ||
            e.toString().contains('TOTP_REQUIRED')) {
          // 2FA flow: state change will trigger UI, then _submitTwoFa()
          return;
        }
        _showError(e.toString());
        _cleanupAfterError();
        return;
      }

      // Phase 2: Get campus DNS and start VPN service
      final updatedConfig = _controller.getConfig();
      // Use campus DNS if available, otherwise use a virtual DNS address
      // (10.255.255.1) that routes through TUN but is NOT the TUN IP.
      // If we use TUN IP (10.0.0.2) as DNS, Android treats it as local
      // and never sends DNS queries through the TUN interface.
      final dns = (updatedConfig?.customDns?.isNotEmpty == true)
          ? '${updatedConfig!.customDns!},10.255.255.1'
          : '10.255.255.1,223.5.5.5';
      await _setupVpnService(rustConfig, dns);

      // Phase 3: Open data channels and start relay
      _controller.openChannelsAndRelay();

      try {
        await startVpnForegroundService();
      } catch (_) {}
    } catch (e) {
      _showError(e.toString());
      _cleanupAfterError();
    }
  }

  /// Create Android VPN service with the given DNS
  Future<void> _setupVpnService(VpnConfig rustConfig, String dns) async {
    if (!Platform.isAndroid) return;

    _vpnFdCompleter = Completer<int>();
    await _vpnChannel?.invokeMethod('startVpn', {
      'address': rustConfig.tunAddress,
      'netmask': rustConfig.tunNetmask,
      'dns': dns,
      'mtu': rustConfig.mtu,
      'routes': '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,202.202.32.0/20',
    });
    try {
      await _vpnFdCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception(t.submodule.sangfor_vpn.vpn_fd_timeout),
      );
    } catch (e) {
      _showError('${t.submodule.sangfor_vpn.vpn_setup_failed}: $e');
      _cleanupAfterError();
      rethrow;
    }
  }

  void _onStateChange(VpnState state) {
    final mapped = mapRustState(state);

    switch (state) {
      case VpnState.waitingSms:
        _showTwoFa = true;
        _isTotp = false;
        addVpnLog(VpnLogLevel.warning, 'Waiting for SMS verification code...');
        break;
      case VpnState.waitingTotp:
        _showTwoFa = true;
        _isTotp = true;
        addVpnLog(VpnLogLevel.warning, 'Waiting for TOTP verification code...');
        break;
      case VpnState.connected:
        _showTwoFa = false;
        addVpnLog(VpnLogLevel.success, 'VPN connected successfully');
        // Start traffic polling
        _startTrafficPolling();
        break;
      case VpnState.disconnected:
        vpnIsRunning.value = false;
        _showTwoFa = false;
        _stopTrafficPolling();
        addVpnLog(VpnLogLevel.info, 'VPN disconnected');
        break;
      case VpnState.error:
        vpnIsRunning.value = false;
        _showTwoFa = false;
        _stopTrafficPolling();
        // Fetch the actual error message from Rust
        final rustError = _controller.getLastError();
        final errorMsg = (rustError != null && rustError.isNotEmpty)
            ? rustError
            : t.submodule.sangfor_vpn.status_check_logcat;
        addVpnLog(VpnLogLevel.error, errorMsg);
        vpnStatus.value = VpnStatusData(
          state: VpnConnectionState.error,
          message: errorMsg,
          config: vpnConfig.value,
        );
        _cleanupAfterError();
        return;
      default:
        break;
    }

    vpnStatus.value = VpnStatusData(state: mapped, config: vpnConfig.value);
  }

  void _showError(String message) {
    addVpnLog(VpnLogLevel.error, message);
    vpnStatus.value = VpnStatusData(
      state: VpnConnectionState.error,
      message: message,
      config: vpnConfig.value,
    );
    vpnIsRunning.value = false;
  }

  Future<void> _cleanupAfterError() async {
    vpnShowConsole.value = false;
    _vpnFdCompleter = null;
    _stateSub?.cancel();
    _stateSub = null;
    _stopTrafficPolling();
    try {
      _controller.disconnect();
    } catch (_) {}
    if (Platform.isAndroid) {
      try {
        await _vpnChannel?.invokeMethod('stopVpn');
      } catch (_) {}
    }
    try {
      await stopVpnForegroundService();
    } catch (_) {}
  }

  Future<void> _submitTwoFa() async {
    final code = _twoFaController.text.trim();
    if (code.isEmpty) return;

    try {
      _twoFaController.clear();
      _showTwoFa = false;

      // Continue auth after 2FA (returns IP)
      _controller.continueAuthAndGetIp(code);

      // Get campus DNS and start VPN service
      final rustConfig = _controller.getConfig() ?? _buildRustConfig();
      final dns = (rustConfig.customDns?.isNotEmpty == true)
          ? rustConfig.customDns!
          : rustConfig.tunAddress;
      await _setupVpnService(rustConfig, dns);

      // Open data channels and start relay
      _controller.openChannelsAndRelay();

      try {
        await startVpnForegroundService();
      } catch (_) {}
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _disconnect() async {
    _vpnFdCompleter = null;

    vpnIsRunning.value = false;
    vpnShowConsole.value = false;
    vpnStatus.value = VpnStatusData(
      state: VpnConnectionState.disconnected,
      config: vpnConfig.value,
    );

    _controller.disconnect();
    _stateSub?.cancel();
    _stateSub = null;
    _stopTrafficPolling();
    if (Platform.isAndroid) {
      try {
        await _vpnChannel?.invokeMethod('stopVpn');
      } catch (_) {}
    }
    try {
      await stopVpnForegroundService();
    } catch (_) {}
  }

  void _startTrafficPolling() {
    _stopTrafficPolling();
    _trafficTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      try {
        final raw = _controller.getTrafficStats();
        if (raw != null) {
          vpnTraffic.value = VpnTrafficStats(
            bytesSent: raw.bytesSent.toInt(),
            bytesReceived: raw.bytesReceived.toInt(),
            packetsSent: raw.packetsSent.toInt(),
            packetsReceived: raw.packetsReceived.toInt(),
          );
        }
      } catch (_) {}
    });
  }

  void _stopTrafficPolling() {
    _trafficTimer?.cancel();
    _trafficTimer = null;
  }

  @override
  void dispose() {
    _stopTrafficPolling();
    _stateSub?.cancel();
    _controller.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _totpSecretController.dispose();
    _dnsController.dispose();
    _twoFaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isRunning = vpnIsRunning.watch(context);
    final status = vpnStatus.watch(context);
    final showConsole = vpnShowConsole.watch(context);

    return PopScope(
      canPop: !isRunning,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              FHeader.nested(
                title: Text(t.submodule.sangfor_vpn.title),
                prefixes: [FHeaderAction.back(onPress: () => context.pop())],
                suffixes: [_buildStatusBadge(context, status.state)],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: [
                          // Status card
                          VpnStatusWidget(
                            state: status.state,
                            message: status.message,
                            isRunning: isRunning,
                          ),

                          // Traffic stats (only when running)
                          if (isRunning) const VpnTrafficWidget(),

                          // Console toggle
                          if (isRunning)
                            FButton(
                              variant: .ghost,
                              size: .sm,
                              onPress: () =>
                                  vpnShowConsole.value = !vpnShowConsole.value,
                              child: Row(
                                spacing: 4,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    showConsole
                                        ? LucideIcons.chevronUp
                                        : LucideIcons.chevronDown,
                                    size: 16,
                                  ),
                                  const Text('Console'),
                                ],
                              ),
                            ),

                          // Console panel
                          if (isRunning && showConsole)
                            const VpnConsoleWidget(),

                          // 2FA section
                          if (_showTwoFa) _buildTwoFaCard(colors),

                          // Config section (hidden when connected)
                          if (!isRunning)
                            VpnConfigSection(
                              serverController: _serverController,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              totpSecretController: _totpSecretController,
                              dnsController: _dnsController,
                            ),

                          // Action button
                          SizedBox(
                            height: 50,
                            child: isRunning
                                ? FButton(
                                    variant: .destructive,
                                    onPress: _disconnect,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      spacing: 8,
                                      children: [
                                        const Icon(
                                          LucideIcons.square,
                                          size: 20,
                                        ),
                                        Text(
                                          t.submodule.sangfor_vpn.disconnect,
                                        ),
                                      ],
                                    ),
                                  )
                                : FButton(
                                    onPress: _connect,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      spacing: 8,
                                      children: [
                                        const Icon(LucideIcons.play, size: 20),
                                        Text(t.submodule.sangfor_vpn.connect),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, VpnConnectionState state) {
    final colors = context.theme.colors;
    final (label, icon, color) = switch (state) {
      VpnConnectionState.connected => (
        t.submodule.sangfor_vpn.status_connected,
        LucideIcons.checkCircle,
        colors.primary,
      ),
      VpnConnectionState.connecting ||
      VpnConnectionState.loginStart ||
      VpnConnectionState.loginPassword ||
      VpnConnectionState.gettingToken ||
      VpnConnectionState.gettingResources ||
      VpnConnectionState.gettingIp ||
      VpnConnectionState.openingChannels => (
        t.submodule.sangfor_vpn.status_connecting,
        LucideIcons.loaderCircle,
        colors.secondary,
      ),
      VpnConnectionState.error => (
        t.submodule.sangfor_vpn.status_failed,
        LucideIcons.circleX,
        colors.destructive,
      ),
      _ => (
        t.submodule.sangfor_vpn.status_disconnected,
        LucideIcons.circle,
        colors.mutedForeground,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 14, color: color),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildTwoFaCard(FColors colors) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(
                  _isTotp ? LucideIcons.keyRound : LucideIcons.messageSquare,
                  size: 20,
                  color: colors.secondary,
                ),
                Text(
                  _isTotp
                      ? t.submodule.sangfor_vpn.totp_verification
                      : t.submodule.sangfor_vpn.sms_verification,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FTextField(
                    control: .managed(controller: _twoFaController),
                    hint: t.submodule.sangfor_vpn.enter_code,
                    keyboardType: TextInputType.number,
                    onSubmit: (_) => _submitTwoFa(),
                  ),
                ),
                FButton(
                  onPress: _submitTwoFa,
                  child: Text(t.submodule.sangfor_vpn.submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
