import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shows a full-screen zoomable image dialog.
///
/// Usage from anywhere:
/// showImageZoomDialog(context, imageUrl);

void showImageZoomDialog(BuildContext context, String imageUrl) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close image',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => _ImageZoomDialog(imageUrl: imageUrl),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

// ── Private dialog widget ────

class _ImageZoomDialog extends StatefulWidget {
  const _ImageZoomDialog({required this.imageUrl});

  final String imageUrl;

  @override
  State<_ImageZoomDialog> createState() => _ImageZoomDialogState();
}

class _ImageZoomDialogState extends State<_ImageZoomDialog>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  static const double _maxScale = 4.0;
  static const double _zoomedScale = 2.5;
  static const double _dismissThreshold = 120;

  double _dragOffset = 0;
  bool _isDragging = false;
  int _pointerCount = 0;
  late final AnimationController _snapBackController;
  late final Animation<double> _snapBackAnimation;

  bool get _isImageAtRest =>
      _transformationController.value.getMaxScaleOnAxis() <= 1.05;

  @override
  void initState() {
    super.initState();

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOut,
    );
    _snapBackAnimation.addListener(() {
      setState(() {
        _dragOffset = (1 - _snapBackAnimation.value) * _dragOffset;
      });
    });
    _snapBackAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dragOffset = 0;
        _isDragging = false;
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * (_zoomedScale - 1),
            -position.dy * (_zoomedScale - 1))
        ..scale(_zoomedScale);
    }
    setState(() => _isZoomed = !_isZoomed);
  }

  void _close() => Navigator.of(context).pop();

  void _onPointerDown(PointerDownEvent event) {
    _pointerCount++;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerCount == 1 && !_isZoomed && _isImageAtRest) {
      final newOffset = _dragOffset + event.delta.dy;
      if (newOffset > 0) {
        setState(() {
          _dragOffset = newOffset;
          _isDragging = true;
        });
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerCount--;
    if (_pointerCount < 0) _pointerCount = 0;
    if (_isDragging) {
      if (_dragOffset > _dismissThreshold) {
        _close();
      } else {
        _snapBack();
      }
    }
    _isDragging = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerCount = 0;
    if (_isDragging) {
      _snapBack();
      _isDragging = false;
    }
  }

  void _snapBack() {
    _snapBackController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final dragProgress = (_dragOffset / _dismissThreshold).clamp(0.0, 1.0);

    return Container(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background overlay that fades with drag 
          IgnorePointer(
            child: Container(
              color: Color.lerp(Colors.transparent, Colors.black, dragProgress),
            ),
          ),

          // ── Draggable content 
          Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Zoomable image 
                    GestureDetector(
                      onDoubleTapDown: _onDoubleTapDown,
                      onDoubleTap: _onDoubleTap,
                      child: InteractiveViewer(
                        transformationController:
                            _transformationController,
                        minScale: 0.8,
                        maxScale: _maxScale,
                        clipBehavior: Clip.none,
                        onInteractionEnd: (details) {
                          final scale = _transformationController
                              .value
                              .getMaxScaleOnAxis();
                          if (scale <= 1.05 && _isZoomed) {
                            setState(() => _isZoomed = false);
                          } else if (scale > 1.05 && !_isZoomed) {
                            setState(() => _isZoomed = true);
                          }
                        },
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            fit: BoxFit.contain,
                            fadeInDuration:
                                const Duration(milliseconds: 200),
                            placeholder: (context, url) =>
                                Shimmer.fromColors(
                              baseColor: const Color(0xFF2A2A2A),
                              highlightColor: const Color(0xFF3D3D3D),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width,
                                height:
                                    MediaQuery.sizeOf(context).height * 0.6,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white54,
                                  size: 56,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Image could not be loaded',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 1.0 - dragProgress,
              child: _TopBar(
                isZoomed: _isZoomed,
                onClose: _close,
                onResetZoom: () {
                  _transformationController.value = Matrix4.identity();
                  setState(() => _isZoomed = false);
                },
              ),
            ),
          ),

          // ── Hint overlay 
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 1.0 - dragProgress,
              child: const _ZoomHint(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar 

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isZoomed,
    required this.onClose,
    required this.onResetZoom,
  });

  final bool isZoomed;
  final VoidCallback onClose;
  final VoidCallback onResetZoom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Close button
            _IconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onTap: onClose,
            ),

            const Spacer(),

            // Reset zoom — only visible when zoomed
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isZoomed
                  ? _IconButton(
                      key: const ValueKey('reset'),
                      icon: Icons.zoom_out_rounded,
                      tooltip: 'Reset zoom',
                      onTap: onResetZoom,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Zoom hint 

class _ZoomHint extends StatefulWidget {
  const _ZoomHint();

  @override
  State<_ZoomHint> createState() => _ZoomHintState();
}

class _ZoomHintState extends State<_ZoomHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Show hint for 2 seconds then fade out
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.pinch_outlined, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'Pinch or double-tap to zoom',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
