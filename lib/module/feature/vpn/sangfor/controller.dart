import 'dart:async';
import 'package:punklorde/src/rust/api/sangfor.dart';
import 'package:punklorde/src/rust/services/sangfor.dart';

/// Sangfor VPN Controller
/// Bridges Flutter -> Rust API calls for VPN management
class SangforVpnController {
  String? _handleId;
  StreamSubscription<VpnState>? _subscription;
  final StreamController<VpnState> _stateController =
      StreamController.broadcast();

  Stream<VpnState> get stateStream => _stateController.stream;
  String? get handleId => _handleId;

  /// Create a new VPN service
  void create(VpnConfig config) {
    _handleId = createVpn(config: config);
  }

  /// Subscribe to state changes
  Future<Stream<VpnState>> subscribe() async {
    if (_handleId == null) throw StateError('VPN not initialized');
    final stream = await subscribeVpnState(handleId: _handleId!);
    _subscription = stream.listen(
      (state) => _stateController.add(state),
      onError: (error) => _stateController.addError(error),
    );
    return _stateController.stream;
  }

  /// Start connection
  void connect() {
    if (_handleId == null) throw StateError('VPN not initialized');
    connectVpn(handleId: _handleId!);
  }

  /// On Android, set the TUN fd from VpnService before connecting
  void setupAndroidTun(int fd) {
    if (_handleId == null) throw StateError('VPN not initialized');
    setTunFd(handleId: _handleId!, fd: fd);
  }

  /// Submit 2FA code
  void submit2fa(String code) {
    if (_handleId == null) throw StateError('VPN not initialized');
    submit2Fa(handleId: _handleId!, code: code);
  }

  /// Phase 1: Authenticate and get the server-assigned IP.
  ///
  /// This is a synchronous blocking call (network I/O, ~2-5 seconds).
  /// Returns the server-assigned IP string.
  /// Throws "SMS_REQUIRED" or "TOTP_REQUIRED" if 2FA is needed.
  /// After 2FA, call [continueAuthAndGetIp] to submit the code and get the IP.
  String authenticateAndGetIp() {
    if (_handleId == null) throw StateError('VPN not initialized');
    return authenticateVpnAndGetIp(handleId: _handleId!);
  }

  /// Continue authentication with a 2FA code and get the server-assigned IP.
  ///
  /// This is a synchronous blocking call.
  /// Call this after [authenticateAndGetIp] threw "SMS_REQUIRED"/"TOTP_REQUIRED"
  /// and the user has provided the verification code.
  /// Returns the server-assigned IP string.
  String continueAuthAndGetIp(String code) {
    if (_handleId == null) throw StateError('VPN not initialized');
    return continueVpnAuthAndGetIp(handleId: _handleId!, code: code);
  }

  /// Phase 2: Open data channels and start TUN relay.
  ///
  /// Must be called after [authenticateAndGetIp] or [continueAuthAndGetIp]
  /// returns the server IP, and after [setupAndroidTun] on Android.
  /// This spawns a background relay thread and returns immediately.
  void openChannelsAndRelay() {
    if (_handleId == null) throw StateError('VPN not initialized');
    openVpnChannelsAndRelay(handleId: _handleId!);
  }

  /// Get the server-assigned IP (non-blocking).
  String? getAssignedIp() {
    if (_handleId == null) return null;
    return getVpnAssignedIp(handleId: _handleId!);
  }

  /// Disconnect
  void disconnect() {
    if (_handleId == null) return;
    disconnectVpn(handleId: _handleId!);
  }

  /// Get current state
  VpnState? getState() {
    if (_handleId == null) return null;
    return getVpnState(handleId: _handleId!);
  }

  /// Get config
  VpnConfig? getConfig() {
    if (_handleId == null) return null;
    return getVpnConfig(handleId: _handleId!);
  }

  /// Check if running
  bool isRunning() {
    if (_handleId == null) return false;
    return isVpnRunning(handleId: _handleId!) ?? false;
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
    if (_handleId != null) {
      disposeVpn(handleId: _handleId!);
    }
    _stateController.close();
  }

  /// Get the last error message from Rust
  /// NOTE: Requires running `flutter_rust_bridge_codegen generate` after Rust changes
  String? getLastError() {
    if (_handleId == null) return null;
    return getVpnLastError(handleId: _handleId!);
  }

  /// Get traffic statistics (returns Rust VpnTrafficStats with BigInt fields)
  VpnTrafficStats? getTrafficStats() {
    if (_handleId == null) return null;
    return getVpnTrafficStats(handleId: _handleId!);
  }
}
