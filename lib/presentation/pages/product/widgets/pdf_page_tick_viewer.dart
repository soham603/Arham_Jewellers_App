import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PdfPageTickViewer extends StatefulWidget {
  final String imageUrl;
  final int imageWidth;
  final int imageHeight;
  final Offset? initialTick;
  final bool interactive;
  final bool showTick;
  final ValueChanged<Offset>? onTickChanged;

  const PdfPageTickViewer({
    super.key,
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    this.initialTick,
    this.interactive = true,
    this.showTick = true,
    this.onTickChanged,
  });

  @override
  State<PdfPageTickViewer> createState() => _PdfPageTickViewerState();
}

class _PdfPageTickViewerState extends State<PdfPageTickViewer> {
  Offset? _tick;

  @override
  void initState() {
    super.initState();
    _tick = widget.initialTick;
  }

  @override
  void didUpdateWidget(covariant PdfPageTickViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTick != widget.initialTick) {
      _tick = widget.initialTick;
    }
  }

  void _handleTap(Rect rect, Offset local) {
    if (!rect.contains(local)) return;

    final x = ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final y = ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0);

    setState(() => _tick = Offset(x, y));
    widget.onTickChanged?.call(Offset(x, y));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        final imageW = widget.imageWidth > 0 ? widget.imageWidth.toDouble() : 1.0;
        final imageH = widget.imageHeight > 0 ? widget.imageHeight.toDouble() : 1.0;

        final fitted = applyBoxFit(BoxFit.contain, Size(imageW, imageH), box);
        final dest = fitted.destination;

        final rect = Rect.fromLTWH(
          (box.width - dest.width) / 2,
          (box.height - dest.height) / 2,
          dest.width,
          dest.height,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.interactive
              ? (details) => _handleTap(rect, details.localPosition)
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.fill,
                  placeholder: (_, _) => Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.white54),
                  ),
                ),
              ),
              if (widget.showTick && _tick != null)
                Positioned(
                  left: rect.left + _tick!.dx * rect.width - 18,
                  top: rect.top + _tick!.dy * rect.height - 18,
                  child: const TickMark(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TickMark extends StatelessWidget {
  const TickMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB8860B), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.check, color: Color(0xFFB8860B), size: 22),
    );
  }
}
