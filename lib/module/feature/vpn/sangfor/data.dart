import 'package:signals/signals_flutter.dart';
import 'package:punklorde/src/rust/services/sangfor.dart';

/// VPN 连接状态（映射自 Rust VpnState）
enum VpnConnectionState {
  disconnected,
  connecting,
  loginStart,
  loginPassword,
  waitingSms,
  waitingTotp,
  gettingToken,
  gettingResources,
  gettingIp,
  openingChannels,
  connected,
  error,
}

/// VPN 状态数据
class VpnStatusData {
  final VpnConnectionState state;
  final String? message;
  final VpnConfigData? config;

  const VpnStatusData({required this.state, this.message, this.config});

  static const initial = VpnStatusData(state: VpnConnectionState.disconnected);

  VpnStatusData copyWith({
    VpnConnectionState? state,
    String? message,
    VpnConfigData? config,
  }) {
    return VpnStatusData(
      state: state ?? this.state,
      message: message ?? this.message,
      config: config ?? this.config,
    );
  }
}

/// VPN 配置（用户可编辑）
class VpnConfigData {
  String server;
  String username;
  String password;
  String totpSecret;
  String? customDns;
  String? splitRoutes;

  VpnConfigData({
    this.server = '',
    this.username = '',
    this.password = '',
    this.totpSecret = '',
    this.customDns,
    this.splitRoutes,
  });

  Map<String, dynamic> toJson() => {
    'server': server,
    'username': username,
    'password': password,
    'totpSecret': totpSecret,
    'customDns': customDns,
    'splitRoutes': splitRoutes,
  };

  factory VpnConfigData.fromJson(Map<String, dynamic> json) => VpnConfigData(
    server: json['server'] ?? '',
    username: json['username'] ?? '',
    password: json['password'] ?? '',
    totpSecret: json['totpSecret'] ?? '',
    customDns: json['customDns'],
    splitRoutes: json['splitRoutes'],
  );
}

// ========== Signals ==========

final Signal<VpnStatusData> vpnStatus = Signal(VpnStatusData.initial);
final Signal<VpnConfigData> vpnConfig = Signal(VpnConfigData());
final Signal<bool> vpnIsRunning = Signal(false);
final Signal<List<VpnLogEntry>> vpnLogs = Signal([]);
final Signal<VpnTrafficStats> vpnTraffic = Signal(VpnTrafficStats.zero);
final Signal<bool> vpnShowConsole = Signal(false);

/// VPN log entry
class VpnLogEntry {
  final DateTime timestamp;
  final VpnLogLevel level;
  final String message;

  VpnLogEntry(this.level, this.message) : timestamp = DateTime.now();

  String get levelLabel {
    switch (level) {
      case VpnLogLevel.info:
        return 'INFO';
      case VpnLogLevel.success:
        return ' OK ';
      case VpnLogLevel.warning:
        return 'WARN';
      case VpnLogLevel.error:
        return ' ERR';
    }
  }
}

enum VpnLogLevel { info, success, warning, error }

/// VPN traffic statistics (updated from Rust via polling)
class VpnTrafficStats {
  final int bytesSent;
  final int bytesReceived;
  final int packetsSent;
  final int packetsReceived;

  const VpnTrafficStats({
    required this.bytesSent,
    required this.bytesReceived,
    required this.packetsSent,
    required this.packetsReceived,
  });

  static const zero = VpnTrafficStats(
    bytesSent: 0,
    bytesReceived: 0,
    packetsSent: 0,
    packetsReceived: 0,
  );

  String get sentFormatted => _formatBytes(bytesSent);
  String get receivedFormatted => _formatBytes(bytesReceived);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

void addVpnLog(VpnLogLevel level, String message) {
  final logs = List<VpnLogEntry>.from(vpnLogs.value);
  logs.add(VpnLogEntry(level, message));
  if (logs.length > 200) logs.removeAt(0); // Keep last 200 entries
  vpnLogs.value = logs;
}

/// Map Rust VpnState to Flutter VpnConnectionState
VpnConnectionState mapRustState(VpnState state) {
  switch (state) {
    case VpnState.disconnected:
      return VpnConnectionState.disconnected;
    case VpnState.connecting:
      return VpnConnectionState.connecting;
    case VpnState.loginStart:
      return VpnConnectionState.loginStart;
    case VpnState.loginPassword:
      return VpnConnectionState.loginPassword;
    case VpnState.waitingSms:
      return VpnConnectionState.waitingSms;
    case VpnState.waitingTotp:
      return VpnConnectionState.waitingTotp;
    case VpnState.gettingToken:
      return VpnConnectionState.gettingToken;
    case VpnState.gettingResources:
      return VpnConnectionState.gettingResources;
    case VpnState.gettingIp:
      return VpnConnectionState.gettingIp;
    case VpnState.openingChannels:
      return VpnConnectionState.openingChannels;
    case VpnState.connected:
      return VpnConnectionState.connected;
    case VpnState.error:
      return VpnConnectionState.error;
  }
}
