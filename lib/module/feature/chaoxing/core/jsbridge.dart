import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// JSBridge 回调类型
typedef JSBridgeCallback =
    void Function(String name, Map<String, dynamic>? payload);

/// JSBridge 消息模型
class JSBridgeMessage {
  final String action;
  final Map<String, dynamic>? data;

  JSBridgeMessage({required this.action, this.data});

  factory JSBridgeMessage.fromJson(Map<String, dynamic> json) {
    return JSBridgeMessage(
      action: json['action'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Flutter 侧 JSBridge
///
/// 负责与 WebView 中的 JS 端 JSBridge 通信。
/// - 注册 `JSBridge` JavaScript handler 接收 JS 侧调用
/// - 通过 `evaluateJavascript` 向 JS 侧发送事件
class ChaoxingJSBridge {
  final InAppWebViewController _controller;

  /// 通知回调：JS 端调用 postNotification 时触发
  JSBridgeCallback? onNotification;

  /// JS Bridge 就绪回调
  VoidCallback? onReady;

  String? _cachedRuntimeScript;

  ChaoxingJSBridge(this._controller);

  /// 初始化：注册 Native handler（只需一次），并注入 JSBridge JS 代码
  Future<void> init() async {
    _controller.addJavaScriptHandler(
      handlerName: 'JSBridge',
      callback: (args) {
        if (args.isEmpty) return;
        try {
          final msg = JSBridgeMessage.fromJson(
            Map<String, dynamic>.from(args[0] as Map),
          );
          handleMessage(msg);
        } catch (e) {
          // ignore parse errors
        }
      },
    );

    await reinject();
  }

  /// 重新注入 JSBridge JS 代码（页面导航后 JS 上下文重置，需要重新注入）
  Future<void> reinject() async {
    _cachedRuntimeScript ??= await rootBundle.loadString(
      "assets/module/chaoxing/scripts/study-wolf.runtime.js",
    );

    await _controller.evaluateJavascript(source: _cachedRuntimeScript!);
    await _controller.evaluateJavascript(source: _platformReadyJS);
  }

  /// 设置客户端信息
  Future<void> setClientInfo(String cid, String sc) async {
    await _controller.evaluateJavascript(
      source:
          '''
sessionStorage.setItem("wolf_cid", "$cid");
sessionStorage.setItem("wolf_sc", "$sc");
''',
    );
  }

  /// 处理来自 JS 的消息
  void handleMessage(JSBridgeMessage msg) {
    switch (msg.action) {
      case 'PostNotification':
        final name = msg.data?['name'] as String?;
        final payload = msg.data?['payload'];
        if (name != null) {
          onNotification?.call(
            name,
            payload is Map ? Map<String, dynamic>.from(payload) : payload,
          );
        }
        break;
      case 'NotificationReady':
        onReady?.call();
        break;
    }
  }

  /// 向 JS 端设置设备类型并标记就绪
  Future<void> setDevice(String device) async {
    await _controller.evaluateJavascript(
      source: "if(window.JSBridge) window.JSBridge.setDevice('$device');",
    );
  }

  /// 向 JS 端触发事件
  Future<void> triggerEvent(String name, Map<String, dynamic>? payload) async {
    final json = payload != null ? jsonEncode(payload) : '{}';
    await _controller.evaluateJavascript(
      source: "if(window.JSBridge) window.JSBridge.trigger('$name', $json);",
    );
  }

  /// 平台就绪事件触发 JS
  static const String _platformReadyJS = '''
(function() {
  if (window.flutterInAppWebViewPlatformReadyFired) return;
  window.flutterInAppWebViewPlatformReadyFired = true;
  window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));
})();
''';
}
