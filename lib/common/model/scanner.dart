import 'package:flutter/material.dart';

/// 扫码结果回调
typedef ScanResultCallback =
    void Function(dynamic result, ScannerController controller);

/// 底部操作栏构建器
typedef ScannerBottomBarBuilder =
    Widget Function(BuildContext context, ScannerController controller);

/// 扫码器控制器接口
abstract class ScannerController {
  bool get torchEnabled;
  bool get isPaused;
  void toggleTorch();
  Future<void> pickImage();

  /// 恢复扫描
  Future<void> resume();
}
