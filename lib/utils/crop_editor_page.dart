import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/constants/image_constants.dart';
import 'package:ratnesh_gold_app/utils/image_crop_helper.dart';

class CropEditorPage extends StatefulWidget {
  final File imageFile;
  final double? aspectRatio;
  final CropInitialState? initialState;

  const CropEditorPage({
    super.key,
    required this.imageFile,
    this.aspectRatio,
    this.initialState,
  });

  @override
  State<CropEditorPage> createState() => _CropEditorPageState();
}

class _CropEditorPageState extends State<CropEditorPage> {
  final ImageEditorController _editorController = ImageEditorController();
  double? _currentAspectRatio;
  double _targetAngle = 0;
  late final Uint8List _imageBytes;

  static const double _minAngle = -45.0;
  static const double _maxAngle = 45.0;

  bool get _showChips => widget.aspectRatio == null;

  @override
  void initState() {
    super.initState();
    _currentAspectRatio = widget.aspectRatio;
    _imageBytes = widget.imageFile.readAsBytesSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyInitialState();
    });
  }

  void _applyInitialState() {
    final initial = widget.initialState;
    if (initial == null) return;

    if (initial.flipY) {
      _editorController.flip(animation: false);
    }

    if (initial.rotationDegrees != 0) {
      _editorController.rotate(degree: initial.rotationDegrees, animation: false);
      _syncAngleFromController();
    }
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  void _setAspectRatio(double? ratio) {
    setState(() => _currentAspectRatio = ratio);
    _editorController.updateCropAspectRatio(ratio);
  }

  void _rotate90Left() {
    _editorController.rotate(degree: -90, animation: true);
    _syncAngleFromController();
  }

  void _rotate90Right() {
    _editorController.rotate(degree: 90, animation: true);
    _syncAngleFromController();
  }

  void _flip() {
    _editorController.flip(animation: true);
  }

  void _syncAngleFromController() {
    final current = _editorController.editActionDetails?.rotateDegrees ?? 0;
    final normalized = _normalizeAngle(current);
    setState(() => _targetAngle = normalized);
  }

  double _normalizeAngle(double degrees) {
    var angle = degrees % 360;
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    if (angle > _maxAngle) angle = _maxAngle;
    if (angle < _minAngle) angle = _minAngle;
    return angle;
  }

  void _onRotationChanged(double value) {
    final current = _editorController.editActionDetails?.rotateDegrees ?? 0;
    final currentNormalized = _normalizeAngle(current);
    final delta = value - currentNormalized;
    if (delta.abs() > 0.01) {
      _editorController.rotate(degree: delta, animation: false);
    }
    setState(() => _targetAngle = value);
  }

  void _onRotationChangeEnd(double value) {
    _editorController.saveCurrentState();
  }

  Future<void> _done() async {
    final state = _editorController.state;
    if (state == null) {
      if (mounted) Navigator.pop(context, null);
      return;
    }

    final cropRect = state.getCropRect();
    final editAction = state.editAction;
    final rawBytes = state.rawImageData;


    final bool noRotation = !(editAction?.hasRotateDegrees ?? false);
    final bool noFlip = !(editAction?.flipY ?? false);
    final bool noCrop = !(editAction?.needCrop ?? false);
    if (noRotation && noFlip && noCrop) {
      if (mounted) {
        Navigator.pop(
          context,
          CropResult(
            file: widget.imageFile,
            rotationDegrees: 0,
            flipY: false,
          ),
        );
      }
      return;
    }

    Rect? effectiveCropRect = cropRect;
    final provider = state.widget.extendedImageState.imageProvider;
    if (cropRect != null && provider is ExtendedResizeImage) {
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(rawBytes);
      final ui.ImageDescriptor descriptor =
          await ui.ImageDescriptor.encoded(buffer);
      final double widthRatio = descriptor.width / state.image!.width;
      final double heightRatio = descriptor.height / state.image!.height;
      effectiveCropRect = Rect.fromLTRB(
        cropRect.left * widthRatio,
        cropRect.top * heightRatio,
        cropRect.right * widthRatio,
        cropRect.bottom * heightRatio,
      );
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    try {
      final tempPath = (await getTemporaryDirectory()).path;
      final result = await compute(_processImageIsolate, _ProcessParams(
        rawBytes: rawBytes,
        cropRectX: effectiveCropRect?.left ?? 0,
        cropRectY: effectiveCropRect?.top ?? 0,
        cropRectW: effectiveCropRect?.width ?? 0,
        cropRectH: effectiveCropRect?.height ?? 0,
        rotateDegrees: editAction?.rotateDegrees ?? 0,
        flipY: editAction?.flipY ?? false,
        needCrop: editAction?.needCrop ?? false,
        tempPath: tempPath,
      ));


      if (mounted) Navigator.pop(context);
      if (!mounted) return;

      if (result != null) {
        Navigator.pop(
          context,
          CropResult(
            file: result,
            rotationDegrees: editAction?.rotateDegrees ?? 0,
            flipY: editAction?.flipY ?? false,
          ),
        );
      } else {
        Navigator.pop(context, null);
      }
    } catch (e, st) {
      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ExtendedImage.memory(
              _imageBytes,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.editor,
              cacheRawData: true,
              initEditorConfigHandler: (state) {
                return EditorConfig(
                  maxScale: 5.0,
                  cropRectPadding: const EdgeInsets.all(20.0),
                  hitTestSize: 25.0,
                  cropAspectRatio: _currentAspectRatio,
                  controller: _editorController,
                  cornerColor: AppColors.primaryGold,
                  lineColor: AppColors.primaryGold,
                  cornerSize: const Size(20, 4),
                );
              },
            ),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 26),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'Edit Image',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo,
            color: _editorController.canUndo ? Colors.white : Colors.white24,
            size: 22,
          ),
          onPressed: _editorController.canUndo
              ? () {
                  _editorController.undo();
                  _syncAngleFromController();
                }
              : null,
        ),
        IconButton(
          icon: Icon(
            Icons.redo,
            color: _editorController.canRedo ? Colors.white : Colors.white24,
            size: 22,
          ),
          onPressed: _editorController.canRedo
              ? () {
                  _editorController.redo();
                  _syncAngleFromController();
                }
              : null,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _done,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.only(bottom: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbar(),
            if (_showChips) ...[
              const SizedBox(height: 12),
              _buildAspectRatioChips(),
            ],
            const SizedBox(height: 12),
            _buildRotationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolbarButton(
            icon: Icons.rotate_left,
            label: 'Rotate L',
            onTap: _rotate90Left,
          ),
          _toolbarButton(
            icon: Icons.rotate_right,
            label: 'Rotate R',
            onTap: _rotate90Right,
          ),
          _toolbarButton(
            icon: Icons.flip,
            label: 'Flip',
            onTap: _flip,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _aspectChip('Free', null),
          const SizedBox(width: 8),
          _aspectChip('1:1', 1),
          const SizedBox(width: 8),
          _aspectChip('3:4', 3 / 4),
          const SizedBox(width: 8),
          _aspectChip('4:3', 4 / 3),
          const SizedBox(width: 8),
          _aspectChip('9:16', 9 / 16),
          const SizedBox(width: 8),
          _aspectChip('16:9', 16 / 9),
        ],
      ),
    );
  }

  Widget _aspectChip(String label, double? ratio) {
    final isSelected = _currentAspectRatio == ratio;
    return GestureDetector(
      onTap: () => _setAspectRatio(ratio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.white10,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRotationSection() {
    final displayAngle = _targetAngle.round();
    final hasRotation = _targetAngle.abs() > 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$displayAngle\u00B0',
          style: TextStyle(
            color: hasRotation ? AppColors.primaryGold : Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          child: _RotationSlider(
            value: _targetAngle,
            min: _minAngle,
            max: _maxAngle,
            onChanged: _onRotationChanged,
            onChangeEnd: _onRotationChangeEnd,
          ),
        ),
      ],
    );
  }
}

class _RotationSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _RotationSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<_RotationSlider> createState() => _RotationSliderState();
}

class _RotationSliderState extends State<_RotationSlider> {
  double _dragStartX = 0;
  double _dragStartValue = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final range = widget.max - widget.min;
        final pixelsPerDegree = width / range;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            _dragStartX = details.localPosition.dx;
            _dragStartValue = widget.value;
          },
          onHorizontalDragUpdate: (details) {
            final deltaPixels = details.localPosition.dx - _dragStartX;
            final deltaDegrees = deltaPixels / pixelsPerDegree;
            final newValue = (_dragStartValue + deltaDegrees).clamp(widget.min, widget.max);
            widget.onChanged(newValue);
          },
          onHorizontalDragEnd: (details) {
            widget.onChangeEnd?.call(widget.value);
          },
          onTapUp: (details) {
            final center = width / 2;
            final newValue = ((details.localPosition.dx - center) / pixelsPerDegree).clamp(widget.min, widget.max);
            widget.onChanged(newValue);
            widget.onChangeEnd?.call(newValue);
          },
          child: CustomPaint(
            size: Size(width, constraints.maxHeight),
            painter: _RotationSliderPainter(
              value: widget.value,
              min: widget.min,
              max: widget.max,
            ),
          ),
        );
      },
    );
  }
}

class _RotationSliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  _RotationSliderPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final height = size.height;
    final range = max - min;

    _drawCenterLine(canvas, center, height);
    _drawTickMarks(canvas, size, center, height, range);
  }

  void _drawCenterLine(Canvas canvas, double center, double height) {
    final paint = Paint()
      ..color = value.abs() > 0.5 ? AppColors.primaryGold : Colors.white54
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center, 0),
      Offset(center, height),
      paint,
    );
  }

  void _drawTickMarks(
    Canvas canvas,
    Size size,
    double center,
    double height,
    double range,
  ) {
    final majorPaint = Paint()..strokeWidth = 1.5;
    final minorPaint = Paint()..strokeWidth = 1.0;
    final pixelsPerDegree = size.width / range;

    for (double degree = min; degree <= max; degree += 2) {
      final isMajor = degree % 20 == 0;
      final paint = isMajor ? majorPaint : minorPaint;

      final offset = center + (degree - value) * pixelsPerDegree;

      if (offset < -5 || offset > size.width + 5) continue;

      final normalizedDistance = (offset - center).abs() / center;
      final edgeFade = math.max(0.0, math.pow(1 - normalizedDistance, 0.35));
      final opacity = (isMajor ? 1.0 : 0.5) * edgeFade;

      final bool passed = (degree < 0 && value <= degree) ||
          (degree > 0 && value >= degree) ||
          (degree == 0 && value.abs() < 0.5);

      final Color tickColor;
      if (passed) {
        tickColor = AppColors.primaryGold.withValues(alpha: opacity);
      } else {
        tickColor = Colors.white.withValues(alpha: opacity * 0.6);
      }

      paint.color = tickColor;

      final tickHeight = isMajor ? height * 0.7 : height * 0.45;
      final top = (height - tickHeight) / 2;

      canvas.drawLine(
        Offset(offset, top),
        Offset(offset, top + tickHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RotationSliderPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _ProcessParams {
  final Uint8List rawBytes;
  final double cropRectX;
  final double cropRectY;
  final double cropRectW;
  final double cropRectH;
  final double rotateDegrees;
  final bool flipY;
  final bool needCrop;
  final String tempPath;

  _ProcessParams({
    required this.rawBytes,
    required this.cropRectX,
    required this.cropRectY,
    required this.cropRectW,
    required this.cropRectH,
    required this.rotateDegrees,
    required this.flipY,
    required this.needCrop,
    required this.tempPath,
  });
}

Future<File?> _processImageIsolate(_ProcessParams params) async {
  final src = img.decodeImage(params.rawBytes);
  if (src == null) return null;

  img.Image result = img.bakeOrientation(src);

  if (params.rotateDegrees != 0) {
    result = img.copyRotate(result, angle: params.rotateDegrees);
  }

  if (params.flipY) {
    result = img.flip(result, direction: img.FlipDirection.horizontal);
  }

  if (params.needCrop && params.cropRectW > 0 && params.cropRectH > 0) {
    result = img.copyCrop(
      result,
      x: params.cropRectX.toInt(),
      y: params.cropRectY.toInt(),
      width: params.cropRectW.toInt(),
      height: params.cropRectH.toInt(),
    );
  }

  final encoded = img.encodeJpg(result, quality: ImageCompressionConstants.cropEditorQuality);
  final file = File('${params.tempPath}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await file.writeAsBytes(encoded);
  return file;
}
