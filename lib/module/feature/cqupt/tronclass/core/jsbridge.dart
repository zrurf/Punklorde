import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

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
class TronclassJSBridge {
  final InAppWebViewController _controller;

  /// JS Bridge 就绪回调
  VoidCallback? onReady;

  TronclassJSBridge(this._controller);

  /// 初始化：注册 Native handler（只需一次），并注入 JSBridge JS 代码
  Future<void> init(BuildContext context) async {
    _controller.addJavaScriptHandler(
      handlerName: 'JSBridge',
      callback: (args) {
        if (args.isEmpty) return;
        try {
          final msg = JSBridgeMessage.fromJson(
            Map<String, dynamic>.from(args[0] as Map),
          );
          _handleMessage(context, msg);
        } catch (e) {
          // ignore parse errors
        }
      },
    );

    await reinject();
  }

  /// 重新注入 JSBridge JS 代码（页面导航后 JS 上下文重置，需要重新注入）
  Future<void> reinject() async {
    await _controller.evaluateJavascript(
      source: '''
window.JSBridge = window.JSBridge || {};
window.JSBridge.callNative = function(action, data){
window.flutter_inappwebview.callHandler('JSBridge', { action, data })
 .catch(err => console.error('InAppWebView callHandler error:', err));
};
''',
    );
  }

  /// 处理来自 JS 的消息
  void _handleMessage(BuildContext context, JSBridgeMessage msg) {
    switch (msg.action) {
      case 'ACT_OPEN_SCANNER':
        // 打开扫码页面
        context.push('/p/universal_scan');
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
  Future<void> triggerEvent(String name, Map<String, dynamic>? userInfo) async {
    final json = userInfo != null ? jsonEncode(userInfo) : '{}';
    await _controller.evaluateJavascript(
      source: "if(window.JSBridge) window.JSBridge.trigger('$name', $json);",
    );
  }
}
