import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/feature/tronclass/config.dart';
import 'package:punklorde/module/feature/tronclass/core/content_blocker.dart';
import 'package:punklorde/module/feature/tronclass/core/jsbridge.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/utils/ua.dart';

/// 畅课 WebView 页面（各校共用）
class TronclassWebviewPage extends StatefulWidget {
  final TronclassConfig config;

  const TronclassWebviewPage({super.key, required this.config});

  @override
  State<TronclassWebviewPage> createState() => _TronclassWebviewPageState();
}

class _TronclassWebviewPageState extends State<TronclassWebviewPage> {
  InAppWebViewController? _controller;
  bool _initialLoadDone = false;
  TronclassJSBridge? _jsBridge;
  bool _bridgeReady = false;

  String get _baseUrl => widget.config.mobileBaseUrl;

  AuthCredential? get _primaryCredential =>
      authManager.getPrimaryAuthByPlatform(widget.config.platform.id);

  /// 受信任域：仅对桌面端/移动端域名显式附带会话头，避免 token 泄漏到第三方
  bool _isTrustedHost(Uri uri) =>
      uri.host == widget.config.apiDomain ||
      uri.host == widget.config.mobileDomain;

  Future<void> _onBackPressed() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
    } else {
      if (!mounted) return;
      context.pop();
    }
  }

  Future<void> _injectCookies(
    InAppWebViewController controller,
    String url,
    AuthCredential credential,
  ) async {
    final cookieManager = CookieManager.instance();
    final rawMap = credential.ext?['cookie'];
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
          if (cookie.domain?.contains(widget.config.apiDomain) == true) {
            await cookieManager.setCookie(
              url: WebUri(url),
              name: cookie.name,
              value: cookie.value,
              domain: widget.config.mobileDomain,
              path: cookie.path ?? "/",
            );
          }
          await cookieManager.setCookie(
            url: WebUri(url),
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain,
            path: cookie.path ?? "/",
          );
        }
      }
    } catch (e) {
      debugPrint('[${widget.config.name}] inject cookies error: $e');
    }
  }

  Future<void> _injectSessionHeaders(
    InAppWebViewController controller,
    String sessionId,
  ) async {
    final escaped = sessionId.replaceAll("'", "\\'");
    await controller.evaluateJavascript(
      source:
          '''
(function() {
  var _sessionId = '$escaped';
  var _origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    this._tronInjected = true;
    return _origOpen.apply(this, arguments);
  };
  var _origSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
  var _origSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.send = function(body) {
    if (this._tronInjected) {
      _origSetRequestHeader.call(this, 'X-SESSION-ID', _sessionId);
      _origSetRequestHeader.call(this, 'SESSION', _sessionId);
    }
    return _origSend.apply(this, arguments);
  };
  if (window.fetch) {
    var _origFetch = window.fetch;
    window.fetch = function(url, options) {
      options = options || {};
      if (options.headers instanceof Headers) {
        options.headers.set('X-SESSION-ID', _sessionId);
        options.headers.set('SESSION', _sessionId);
      } else {
        options.headers = options.headers || {};
        options.headers['X-SESSION-ID'] = _sessionId;
        options.headers['SESSION'] = _sessionId;
      }
      return _origFetch.call(this, url, options);
    };
  }
})();
''',
    );
  }

  Future<void> _injectStyle(InAppWebViewController controller) async {
    await controller.evaluateJavascript(
      source: '''
(function() {
document.documentElement.style.setProperty('--safe-area-inset-top','0');
document.documentElement.style.setProperty('--ion-safe-area-top','0');
document.documentElement.style.setProperty('--safe-area-inset-bottom','0');
document.documentElement.style.setProperty('--ion-safe-area-bottom','0');
})();
''',
    );
  }

  Future<void> _injectRuntimeScript(InAppWebViewController controller) async {
    await controller.evaluateJavascript(
      source: '''
(function() {
  const s = [
    document.querySelector('[data-testid="scanAction"]'),
    document.querySelector('[data-testid="quickscan"]'),
  ].filter(item => item != null);
  for (const e of s) {
    const clone = e.cloneNode(true);
    clone.addEventListener('click', (e) => {
      JSBridge.callNative('ACT_OPEN_SCANNER', {});
      e.stopPropagation();
    });
    e.parentNode?.replaceChild(clone, e);
  }
})();
''',
    );
  }

  /// 主文档/导航请求显式携带 x-session-id（仅受信任域）
  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final req = action.request;
    final url = req.url;
    if (url == null) {
      return NavigationActionPolicy.ALLOW;
    }
    final hasSessionHeader =
        req.headers?.keys.any((k) => k.toLowerCase() == 'x-session-id') ??
        false;
    if (hasSessionHeader || !_isTrustedHost(url)) {
      return NavigationActionPolicy.ALLOW;
    }
    final credential = _primaryCredential;
    if (credential == null) {
      return NavigationActionPolicy.ALLOW;
    }
    // 当前版本不支持返回替换请求：取消后手动携带会话头重载
    unawaited(
      controller.loadUrl(
        urlRequest: URLRequest(
          url: url,
          method: req.method,
          headers: {...?req.headers, 'x-session-id': credential.token},
        ),
      ),
    );
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final credential = _primaryCredential;

    if (credential == null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: Text(
              '请先登录${widget.config.name}',
              style: TextStyle(color: colors.mutedForeground),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(colors, credential),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("about:blank")),
                  initialSettings: InAppWebViewSettings(
                    userAgent: UAUtil.getUA(.raw),
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    mixedContentMode:
                        MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    supportZoom: true,
                    builtInZoomControls: true,
                    displayZoomControls: false,
                    scrollBarStyle: ScrollBarStyle.SCROLLBARS_OUTSIDE_OVERLAY,
                    verticalScrollBarEnabled: true,
                    horizontalScrollBarEnabled: false,
                    contentBlockers: [TronclassContentBlocker.envGuardBlocker],
                    isInspectable: kDebugMode,
                  ),
                  onWebViewCreated: (controller) async {
                    _controller = controller;

                    _jsBridge = TronclassJSBridge(controller);
                    _jsBridge!.onReady = () {
                      if (!_bridgeReady) {
                        _bridgeReady = true;
                      }
                    };
                    await _jsBridge!.init(context);

                    await _injectCookies(controller, _baseUrl, credential);
                  },
                  shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                  onLoadStop: (controller, url) async {
                    await _injectSessionHeaders(controller, credential.token);

                    if (!_initialLoadDone) {
                      _initialLoadDone = true;
                      // 主文档请求显式携带 x-session-id，避免移动端域
                      // cookie 未就绪时被重定向到登录页
                      await controller.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(_baseUrl),
                          headers: {'x-session-id': credential.token},
                        ),
                      );
                      return;
                    }

                    if (_jsBridge != null && !_bridgeReady) {
                      await _jsBridge!.reinject();
                    }

                    _injectStyle(controller);
                    _injectRuntimeScript(controller);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FColors colors, AuthCredential credential) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        spacing: 4,
        children: [
          // 后退按钮 — WebView 回退
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBackPressed(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: colors.mutedForeground,
              ),
            ),
          ),
          // 关闭按钮 — 退出模块
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (mounted) context.pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.x,
                size: 20,
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.config.bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(widget.config.iconAsset),
            ),
          ),
          Text(
            widget.config.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // 刷新按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _controller?.reload(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.refreshCcw,
                size: 18,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
