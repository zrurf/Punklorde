import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/feature/chaoxing/core/js_handler.dart';
import 'package:punklorde/module/feature/chaoxing/view/widgets/chaoxing_webview.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';

class ChaoxingWebViewPage extends StatefulWidget {
  final String url;
  final String? title;

  const ChaoxingWebViewPage({super.key, required this.url, this.title});

  @override
  State<ChaoxingWebViewPage> createState() => _ChaoxingWebViewPageState();
}

class _ChaoxingWebViewPageState extends State<ChaoxingWebViewPage> {
  InAppWebViewController? _controller;
  ChaoxingJSHandler? _jsHandler;

  Future<void> _onBackPressed() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
    } else {
      if (!mounted) return;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final credential = authManager.getPrimaryAuthByPlatform(platChaoxing.id);

    if (credential == null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: Text(
              '请先登录学习通',
              style: TextStyle(color: colors.mutedForeground),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(colors),
              Expanded(
                child: ChaoxingWebView(
                  config: ChaoxingWebViewConfig(
                    url: widget.url,
                    credential: credential,
                    userAgent: credential.ext?["ua"],
                    onPageStarted: (controller, url) {
                      _controller = controller;
                      _jsHandler = ChaoxingJSHandler(
                        controller,
                        onOpenUrl: (newUrl) async {
                          _controller?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(newUrl)),
                          );
                        },
                      );
                    },
                    onJSBridgeNotification: (name, payload) {
                      _jsHandler?.handle(name, payload);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FColors colors) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onBackPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xffe9002d),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/images/app/chaoxing.png'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title ?? platChaoxing.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 扫码按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/p/universal_scan'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.scanLine,
                size: 18,
                color: colors.mutedForeground,
              ),
            ),
          ),
          // 刷新按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _controller?.reload(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.refreshCw,
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
