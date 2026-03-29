import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:punklorde/common/model/scanner.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

class ScannerWidget extends StatefulWidget {
  final ScanResultCallback onResult;
  final ScannerBottomBarBuilder? bottomBarBuilder;
  final Widget? topBarButton;

  const ScannerWidget({
    super.key,
    required this.onResult,
    this.bottomBarBuilder,
    this.topBarButton,
  });

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget>
    with TickerProviderStateMixin {
  late final MobileScannerController _controller;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  final _torchEnabled = signal(false);
  final _isPaused = signal(false);
  final _showMultiSelectOverlay = signal(false);
  final _detectedBarcodes = signal<List<Barcode>>([]);
  final _captureSize = signal<Size?>(null);
  final _frozenImage = signal<Uint8List?>(null);
  double _zoomScale = 1;
  double _lastZoomScale = 1;

  Timer? _debounceTimer;
  List<Barcode> _frameBuffer = [];
  final int _debounceDelay = 500;

  late final AnimationController _scanLineAnimationController;
  late final ScannerController _scannerController = _ScannerControllerImpl(
    this,
  );

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _scanLineAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    _scanLineAnimationController.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastZoomScale = 1;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final double d = (details.scale - _lastZoomScale).clamp(-1, 1);
    _lastZoomScale = details.scale;
    _zoomScale += d;
    _controller.setZoomScale(_zoomScale / 2);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isPaused.value) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    _frameBuffer = barcodes;
    if (capture.size != Size.zero) {
      _captureSize.value = capture.size;
    }

    if (barcodes.length > 1) {
      _debounceTimer?.cancel();
      _enterMultiSelectMode(barcodes, capture.size);
      return;
    }

    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(Duration(milliseconds: _debounceDelay), () {
      if (_isPaused.value) return;
      if (_frameBuffer.length > 1) {
        _enterMultiSelectMode(_frameBuffer, _captureSize.value ?? Size.zero);
      } else if (_frameBuffer.length == 1) {
        _handleResult(_frameBuffer.first);
      }
    });
  }

  Future<void> _enterMultiSelectMode(List<Barcode> barcodes, Size size) async {
    _isPaused.value = true;
    _detectedBarcodes.value = barcodes;
    if (size != Size.zero) _captureSize.value = size;

    await _captureAndFreezeScreen();
    _controller.stop();
    _showMultiSelectOverlay.value = true;
  }

  Future<void> _captureAndFreezeScreen() async {
    try {
      RenderRepaintBoundary? boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          _frozenImage.value = byteData.buffer.asUint8List();
        }
      }
    } catch (e) {
      debugPrint("Unable to save the screen: $e");
    }
  }

  void _handleResult(Barcode barcode) {
    // 立即暂停逻辑，防止重复触发
    _isPaused.value = true;

    // 清除UI状态
    _showMultiSelectOverlay.value = false;
    _frozenImage.value = null;

    // 停止相机
    _controller.stop();

    final result = barcode.rawValue ?? barcode.rawDecodedBytes;
    if (result != null) {
      // 将控制权交给外部，传递 controller 以便外部可以恢复
      widget.onResult(result, _scannerController);
    }
  }

  void _onMultiCodeSelected(Barcode barcode) {
    _showMultiSelectOverlay.value = false;
    _handleResult(barcode);
  }

  void _toggleTorch() {
    _torchEnabled.value = !_torchEnabled.value;
    _controller.toggleTorch();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final path = image.path;
    final result = await _controller.analyzeImage(path);

    if (result != null && result.barcodes.isNotEmpty) {
      _handleResult(result.barcodes.first);
    }
  }

  /// 恢复扫描逻辑
  Future<void> _resume() async {
    if (!_isPaused.value) return;

    _isPaused.value = false;
    _torchEnabled.value = false;
    _frozenImage.value = null;
    _frameBuffer = [];

    // 重新启动相机
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onTapDown: (details) {
        _controller.setFocusPoint(details.localPosition);
      },
      child: Stack(
        children: [
          Watch((context) {
            final image = _frozenImage.watch(context);
            if (image != null && _isPaused.value) {
              return Positioned.fill(child: Image.memory(image, fit: .cover));
            }
            return const SizedBox.shrink();
          }),

          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              tapToFocus: true,
              errorBuilder: (context, error) {
                return Center(
                  child: Text(
                    'No permission: ${error.errorCode}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),

          Watch((context) {
            final isPaused = _isPaused.watch(context);
            if (isPaused) return const SizedBox.shrink();
            return _buildScanAnimation();
          }),

          Watch((context) {
            final showOverlay = _showMultiSelectOverlay.watch(context);
            if (!showOverlay) return const SizedBox.shrink();
            return _buildMultiSelectButtons();
          }),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const .symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    crossAxisAlignment: .center,
                    children: [
                      widget.topBarButton ??
                          FButton.icon(
                            size: .xs,
                            variant: .ghost,
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.white,
                              size: 25,
                            ),
                            onPress: () => context.pop(),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: .bottomCenter,
            child:
                widget.bottomBarBuilder?.call(context, _scannerController) ??
                _buildDefaultBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBottomControls() {
    return SafeArea(
      child: Container(
        height: 120,
        padding: const .only(bottom: 30),
        child: Row(
          mainAxisAlignment: .spaceEvenly,
          children: [
            Watch((context) {
              final isPaused = _isPaused.watch(context);
              if (isPaused) return const SizedBox(width: 60);
              return _buildCircleButton(
                icon: LucideIcons.image,
                onTap: _pickImage,
              );
            }),
            Watch((context) {
              final torchOn = _torchEnabled.watch(context);
              final isPaused = _isPaused.watch(context);
              if (isPaused) return const SizedBox(width: 60);
              return _buildCircleButton(
                icon: LucideIcons.flashlight,
                onTap: _toggleTorch,
                isActive: torchOn,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withValues(alpha: 0.8)
              : Colors.black54,
          shape: .circle,
          border: .all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildScanAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = context.theme.colors;
        return AnimatedBuilder(
          animation: _scanLineAnimationController,
          builder: (context, child) {
            return CustomPaint(
              size: .infinite,
              painter: _ScanLinePainter(
                progress: _scanLineAnimationController.value,
                lineColor: Colors.white.withValues(alpha: 0.8),
                glowColor: colors.primary,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMultiSelectButtons() {
    final colors = context.theme.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = constraints.biggest;
        final imageSize = _captureSize.value;

        if (imageSize == null || imageSize == Size.zero) {
          return const SizedBox.shrink();
        }

        final double scaleX = screenSize.width / imageSize.width;
        final double scaleY = screenSize.height / imageSize.height;
        final double scale = scaleX > scaleY ? scaleX : scaleY;

        final double dx = (screenSize.width - imageSize.width * scale) / 2;
        final double dy = (screenSize.height - imageSize.height * scale) / 2;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const .symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: .circular(20),
                  ),
                  child: Text(
                    t.notice.multi_codes_select,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
            ..._detectedBarcodes.value.map((barcode) {
              if (barcode.corners.isEmpty) return const SizedBox.shrink();

              final corners = barcode.corners;
              double sumX = 0, sumY = 0;
              for (var p in corners) {
                sumX += p.dx;
                sumY += p.dy;
              }
              final centerX = sumX / corners.length;
              final centerY = sumY / corners.length;

              final double screenX = centerX * scale + dx;
              final double screenY = centerY * scale + dy;

              return Positioned(
                left: screenX - 30,
                top: screenY - 30,
                child: GestureDetector(
                  onTap: () => _onMultiCodeSelected(barcode),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.9),
                      shape: .circle,
                      border: .all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: colors.background.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.arrowRight,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _ScannerControllerImpl implements ScannerController {
  final _ScannerWidgetState _state;
  _ScannerControllerImpl(this._state);

  @override
  bool get torchEnabled => _state._torchEnabled.value;
  @override
  bool get isPaused => _state._isPaused.value;
  @override
  void toggleTorch() => _state._toggleTorch();
  @override
  Future<void> pickImage() => _state._pickImage();

  @override
  Future<void> resume() => _state._resume();
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final Color glowColor;

  _ScanLinePainter({
    required this.progress,
    required this.lineColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final width = size.width;
    final maxThickness = 4.0;

    Path linePath = Path();
    linePath.moveTo(0, y);
    linePath.quadraticBezierTo(width / 2, y - maxThickness, width, y);
    linePath.quadraticBezierTo(width / 2, y + maxThickness, 0, y);
    linePath.close();

    final rect = Rect.fromLTWH(0, y - maxThickness, width, maxThickness * 2);
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        lineColor.withValues(alpha: 0.0),
        lineColor,
        lineColor,
        lineColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.2, 0.8, 1.0],
    );

    final linePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final shadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, shadowPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
