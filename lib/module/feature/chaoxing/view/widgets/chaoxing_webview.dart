import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/module/feature/chaoxing/core/content_blocker.dart';
import 'package:punklorde/module/feature/chaoxing/core/jsbridge.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/utils/ua.dart';

/// WebView 配置
class ChaoxingWebViewConfig {
  final String url;
  final AuthCredential credential;
  final String? userAgent;
  final String? injectCSS;
  final String? injectJS;
  final bool injectOnLoad;

  /// 资源拦截
  final WebResourceResponse? Function(WebResourceRequest request)?
  onShouldInterceptRequest;

  /// JSBridge 通知回调
  final JSBridgeCallback? onJSBridgeNotification;

  /// JSBridge 就绪回调
  final VoidCallback? onJSBridgeReady;

  /// 页面加载完成
  final void Function(InAppWebViewController controller, String? url)?
  onPageFinished;

  /// 页面开始加载
  final void Function(InAppWebViewController controller, String? url)?
  onPageStarted;

  /// 控制台消息
  final void Function(String message)? onConsoleMessage;

  const ChaoxingWebViewConfig({
    required this.url,
    required this.credential,
    this.userAgent,
    this.injectCSS,
    this.injectJS,
    this.injectOnLoad = true,
    this.onShouldInterceptRequest,
    this.onJSBridgeNotification,
    this.onJSBridgeReady,
    this.onPageFinished,
    this.onPageStarted,
    this.onConsoleMessage,
  });
}

/// 通用学习通 WebView 控件
class ChaoxingWebView extends StatefulWidget {
  final ChaoxingWebViewConfig config;

  const ChaoxingWebView({super.key, required this.config});

  @override
  State<ChaoxingWebView> createState() => _ChaoxingWebViewState();
}

class _ChaoxingWebViewState extends State<ChaoxingWebView> {
  InAppWebViewController? _webViewController;
  ChaoxingJSBridge? _jsBridge;
  bool _bridgeReady = false;
  bool _initialLoadDone = false;

  @override
  Widget build(BuildContext context) {
    final credential = widget.config.credential;
    final ua =
        widget.config.userAgent ??
        (credential.ext?['ua'] as String?) ??
        UAUtil.getUA(.raw);

    final clientInfoStr = credential.ext?['client_info'] as String? ?? '{}';
    String clientCid = '';
    String clientSc = '';
    try {
      final clientInfo = jsonDecode(clientInfoStr);
      clientCid = clientInfo['cid'].toString();
      clientSc = clientInfo['sc'].toString();
    } catch (e) {
      print(e);
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("about:blank")),
      initialSettings: InAppWebViewSettings(
        userAgent: ua,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        contentBlockers: [ChaoxingContentBlocker.jsBridgeBlocker],
        scrollBarStyle: ScrollBarStyle.SCROLLBARS_OUTSIDE_OVERLAY,
        verticalScrollBarEnabled: true,
        horizontalScrollBarEnabled: false,
        isInspectable: kDebugMode,
      ),
      onWebViewCreated: (controller) async {
        _webViewController = controller;
        _jsBridge = ChaoxingJSBridge(controller);
        _jsBridge!.onNotification = widget.config.onJSBridgeNotification;
        _jsBridge!.onReady = () {
          if (!_bridgeReady) {
            _bridgeReady = true;
            widget.config.onJSBridgeReady?.call();
          }
        };
        await _jsBridge!.init();
        await _injectCookies(controller, widget.config.url);
      },
      onLoadStop: (controller, url) async {
        if (!_initialLoadDone) {
          _initialLoadDone = true;
          // 使用 location.replace 避免 about:blank 残留在历史记录中
          final escaped = widget.config.url.replaceAll("'", "\\'");
          controller.evaluateJavascript(
            source: "window.location.replace('$escaped');",
          );
          return;
        }
        if (_jsBridge != null && !_bridgeReady) {
          await _jsBridge!.reinject();
          await _jsBridge!.setClientInfo(clientCid, clientSc);
        }

        // 注入自定义 CSS / JS
        if (widget.config.injectCSS != null && widget.config.injectOnLoad) {
          await _injectCSS(controller, widget.config.injectCSS!);
        }
        if (widget.config.injectJS != null && widget.config.injectOnLoad) {
          await controller.evaluateJavascript(source: widget.config.injectJS!);
        }

        widget.config.onPageFinished?.call(controller, url?.toString());
      },
      onLoadStart: (controller, url) async {
        _bridgeReady = false;
        if (_jsBridge != null && !_bridgeReady) {
          await _jsBridge!.reinject();
          await _jsBridge!.setClientInfo(clientCid, clientSc);
        }
        widget.config.onPageStarted?.call(controller, url?.toString());
      },
      shouldInterceptRequest: widget.config.onShouldInterceptRequest != null
          ? (controller, request) {
              return widget.config.onShouldInterceptRequest!(request);
            }
          : null,
      onConsoleMessage: widget.config.onConsoleMessage != null
          ? (controller, msg) {
              widget.config.onConsoleMessage!(msg.message);
            }
          : null,
    );
  }

  Future<void> _injectCookies(
    InAppWebViewController controller,
    String url,
  ) async {
    final cookieManager = CookieManager.instance();
    final rawMap = widget.config.credential.ext?['cookie'];
    if (rawMap == null || rawMap is! Map) return;
    try {
      final cookieMap = <String, List<String>>{};
      rawMap.forEach((key, value) {
        cookieMap[key.toString()] = List<String>.from(value as List);
      });
      final jar = await deserializeCookieJar(cookieMap);

      for (final entry in cookieMap.entries) {
        final uri = entry.key;
        final cookies = await jar.loadForRequest(Uri.parse(uri));
        for (final cookie in cookies) {
          final r = await cookieManager.setCookie(
            url: WebUri(url),
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain,
            path: cookie.path ?? "/",
          );
          if (!r) {
            debugPrint('[ChaoxingWebView] inject cookie error: $cookie');
          }
        }
      }
    } catch (e) {
      debugPrint('[ChaoxingWebView] inject cookies error: $e');
    }
  }

  Future<void> _injectCSS(InAppWebViewController controller, String css) async {
    final escaped = css.replaceAll("'", "\\'").replaceAll('\n', ' ');
    await controller.evaluateJavascript(
      source:
          "(function(){var s=document.createElement('style');s.textContent='$escaped';document.head.appendChild(s);})();",
    );
  }

  InAppWebViewController? get controller => _webViewController;

  ChaoxingJSBridge? get jsBridge => _jsBridge;

  Future<dynamic> evaluateJavascript(String source) async {
    return _webViewController?.evaluateJavascript(source: source);
  }
}
