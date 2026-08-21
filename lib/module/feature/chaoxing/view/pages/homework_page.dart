import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/core/js_handler.dart';
import 'package:punklorde/module/feature/chaoxing/view/widgets/chaoxing_webview.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';

class HomeworkPage extends StatefulWidget {
  /// 页面 URL 变化回调，isAtHomeUrl 表示是否在作业首页
  final void Function(bool isAtHomeUrl)? onPageChanged;

  const HomeworkPage({super.key, this.onPageChanged});

  @override
  State<HomeworkPage> createState() => HomeworkPageState();
}

class HomeworkPageState extends State<HomeworkPage> {
  static const String _homeworkUrl =
      'https://mooc1-api.chaoxing.com/work/stu-work';

  InAppWebViewController? _webviewController;
  ChaoxingJSHandler? _jsHandler;

  @override
  void dispose() {
    _jsHandler?.dispose();
    super.dispose();
  }

  /// 父组件可通过 GlobalKey 调用，用于标题栏回退
  Future<bool> goBack() async {
    if (_webviewController == null) return false;
    final canGoBack = await _webviewController!.canGoBack();
    if (canGoBack) {
      _webviewController!.goBack();
      return true;
    }
    return false;
  }

  /// 刷新 WebView
  void reload() {
    _webviewController?.reload();
  }

  void _notifyPageChanged(String? url) {
    if (widget.onPageChanged == null || url == null) return;
    final uri = Uri.tryParse(url);
    final homeUri = Uri.tryParse(_homeworkUrl);
    if (uri == null || homeUri == null) return;
    // 同 host + path 前缀视为仍在作业首页
    final isAtHome =
        uri.host == homeUri.host && uri.path.startsWith(homeUri.path);
    widget.onPageChanged!(isAtHome);
  }

  @override
  Widget build(BuildContext context) {
    final credential = authManager.getPrimaryAuthByPlatform(platChaoxing.id);

    if (credential == null) {
      return _buildNotLogin(context);
    }

    return ChaoxingWebView(
      config: ChaoxingWebViewConfig(
        url: _homeworkUrl,
        credential: credential,
        userAgent: credential.ext?["ua"],
        onPageStarted: (controller, jsBridge, url) {
          _webviewController = controller;
          _jsHandler = ChaoxingJSHandler(
            controller,
            jsBridge,
            onOpenUrl: (newUrl) async {
              _webviewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(newUrl)),
              );
            },
          );
          _notifyPageChanged(url);
        },
        onJSBridgeNotification: (name, payload) {
          _jsHandler?.handle(name, payload);
        },
      ),
    );
  }

  Widget _buildNotLogin(BuildContext context) {
    return Center(
      child: Text(t.notice.not_login, style: const TextStyle(fontSize: 16)),
    );
  }
}
