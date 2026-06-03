import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({
    super.key,
    required this.onDetect,
  });

  final FutureOr<void> Function(String barcode) onDetect;

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  bool _isProcessing = false;
  bool _isStarting = false;
  bool _isScannerRunning = false;
  bool _torchOn = false;
  String? _errorMessage;

  String? _lastScannedValue;
  DateTime? _lastScannedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startScanner());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      if (!_isProcessing) {
        unawaited(_startScanner());
      }
    } else {
      unawaited(_stopScanner());
    }
  }

  bool _isDuplicateScan(String value) {
    final now = DateTime.now();

    final isDuplicate = _lastScannedValue == value &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(seconds: 2);

    _lastScannedValue = value;
    _lastScannedAt = now;

    return isDuplicate;
  }

  Future<void> _startScanner() async {
    if (!mounted || _isStarting || _isProcessing || _isScannerRunning) return;

    _isStarting = true;

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    try {
      await _controller.start();
      _isScannerRunning = true;
    } catch (e, stackTrace) {
      debugPrint('Failed to start scanner: $e\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to access the camera. Check camera permissions and try again.';
      });
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _stopScanner() async {
    if (!_isScannerRunning) return;

    try {
      await _controller.stop();
    } catch (_) {
      // Ignore stop errors during lifecycle changes.
    } finally {
      _isScannerRunning = false;
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Failed to toggle torch: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (e) {
      debugPrint('Failed to switch camera: $e');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .firstWhere(
          (rawValue) => rawValue.isNotEmpty,
          orElse: () => '',
        );

    if (value.isEmpty || _isDuplicateScan(value)) {
      return;
    }

    setState(() => _isProcessing = true);
    await _stopScanner();

    try {
      await widget.onDetect(value);
    } catch (e, stackTrace) {
      debugPrint('Barcode processing failed: $e\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'The barcode was scanned, but could not be processed. Please try again.';
        _isProcessing = false;
      });

      unawaited(_startScanner());
      return;
    }

    if (!mounted) return;

    // For one-time scan, pop the value and close
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actions: [
          IconButton(
            tooltip: _torchOn ? 'Turn flash off' : 'Turn flash on',
            onPressed: _isProcessing ? null : _toggleTorch,
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _isProcessing ? null : _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const _ScannerOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Align the barcode inside the frame',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_errorMessage != null) ...[
                    _MessageCard(
                      message: _errorMessage!,
                      actionLabel: 'Try again',
                      onAction: _startScanner,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tip: hold the device steady and make sure the barcode is well lit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator.adaptive(),
                      SizedBox(height: 12),
                      Text(
                        'Processing...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade700.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                unawaited(onAction());
              },
              child: Text(
                actionLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scanWidth = constraints.maxWidth * 0.78;
          final scanHeight = scanWidth * 0.42;

          final scanWindow = Rect.fromCenter(
            center: Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            ),
            width: scanWidth,
            height: scanHeight,
          );

          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _ScannerOverlayPainter(scanWindow: scanWindow),
          );
        },
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.scanWindow});

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      );

    canvas.drawPath(
      backgroundPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final cornerPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;

    // Top-left
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top + cornerLength),
      Offset(scanWindow.left, scanWindow.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top),
      Offset(scanWindow.left + cornerLength, scanWindow.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(scanWindow.right - cornerLength, scanWindow.top),
      Offset(scanWindow.right, scanWindow.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.right, scanWindow.top),
      Offset(scanWindow.right, scanWindow.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.bottom - cornerLength),
      Offset(scanWindow.left, scanWindow.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.bottom),
      Offset(scanWindow.left + cornerLength, scanWindow.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(scanWindow.right - cornerLength, scanWindow.bottom),
      Offset(scanWindow.right, scanWindow.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.right, scanWindow.bottom - cornerLength),
      Offset(scanWindow.right, scanWindow.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}