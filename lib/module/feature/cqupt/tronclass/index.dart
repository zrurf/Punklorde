import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/core/content_blocker.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/core/jsbridge.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';
import 'package:punklorde/utils/ua.dart';

class FeatCquptTronclassView extends StatefulWidget {
  const FeatCquptTronclassView({super.key});

  @override
  State<FeatCquptTronclassView> createState() => _FeatCquptTronclassViewState();
}

class _FeatCquptTronclassViewState extends State<FeatCquptTronclassView> {
  static const String _baseUrl = "http://mobile.tc.cqupt.edu.cn/";

  InAppWebViewController? _controller;
  bool _initialLoadDone = false;
  TronclassJSBridge? _jsBridge;
  bool _bridgeReady = false;

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
          if (cookie.domain?.contains("lms.tc.cqupt.edu.cn") == true) {
            await cookieManager.setCookie(
              url: WebUri(url),
              name: cookie.name,
              value: cookie.value,
              domain: "mobile.tc.cqupt.edu.cn",
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
      debugPrint('[Tronclass] inject cookies error: $e');
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

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final credential = authManager.getPrimaryAuthByPlatform(
      platCquptTronclass.id,
    );

    if (credential == null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: Text(
              '请先登录学在重邮',
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
                  onLoadStop: (controller, url) async {
                    await _injectSessionHeaders(controller, credential.token);

                    if (!_initialLoadDone) {
                      _initialLoadDone = true;
                      // 使用 location.replace 避免 about:blank 残留在历史记录中
                      final escaped = _baseUrl.replaceAll("'", "\\'");
                      controller.evaluateJavascript(
                        source: "window.location.replace('$escaped');",
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
              color: const Color(0xff1177b0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/images/app/tronclass.png'),
            ),
          ),
          Text(
            platCquptTronclass.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
