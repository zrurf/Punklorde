import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:punklorde/module/feature/chaoxing/core/jsbridge.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChaoxingJSHandler {
  final InAppWebViewController _controller;
  final ChaoxingJSBridge _jsBridge;
  final Future<void> Function(String url)? onOpenUrl;

  ChaoxingJSHandler(this._controller, this._jsBridge, {this.onOpenUrl});

  /// 释放资源
  void dispose() {}

  Future<void> handle(String name, dynamic payload) async {
    try {
      switch (name.toUpperCase()) {
        // 打开 URL
        case 'CLIENT_OPEN_URL':
          if (payload is Map) {
            await opOpenUrl(Map<String, dynamic>.from(payload)["webUrl"]);
          }
          break;

        // 页面生命周期
        case 'CLIENT_WEB_LIFECYCLE':
          break;

        // 检查手机环境
        case 'CLIENT_PHONE_ENVIRONMENT_CHECK':
          if (payload is Map && payload["enable"] == 1) {
            await _jsBridge.triggerEvent(name, {
              "developSettingEnable": 0,
              "usbDebugEnable": 0,
              "canMockPosition": 0,
            });
          }
          break;

        // 设置禁止锁屏
        case 'CLIENT_SCREEN_LOCK':
          if (payload is Map && payload["forbiddenFlag"] == "1") {
            WakelockPlus.enable();
          } else {
            WakelockPlus.disable();
          }
          break;

        default:
          await opOther(name, payload);
          break;
      }
    } catch (e) {
      print('ChaoxingJSHandler error ($name): $e');
    }
  }

  /// Push 新路由打开 URL，而非在当前 WebView 内替换
  Future<void> opOpenUrl(String url) async {
    if (onOpenUrl != null) {
      await onOpenUrl!(url);
    }
  }

  Future<void> opOther(String name, dynamic payload) async {}
}
