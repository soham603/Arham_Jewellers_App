import 'dart:math';
import 'package:flutter/material.dart';

class LineGraphLogo extends StatelessWidget {
  final double size;
  final Color color;

  const LineGraphLogo({
    super.key,
    this.size = 36,
    this.color = const Color(0xFFB8860B),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LineGraphPainter(color: color),
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final Color color;

  _LineGraphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.25),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final padding = size.width * 0.18;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    final points = [
      Offset(0.0, 0.55),
      Offset(0.12, 0.48),
      Offset(0.25, 0.60),
      Offset(0.38, 0.30),
      Offset(0.50, 0.38),
      Offset(0.62, 0.15),
      Offset(0.75, 0.22),
      Offset(0.88, 0.08),
      Offset(1.0, 0.18),
    ].map((p) => Offset(padding + p.dx * w, padding + p.dy * h)).toList();

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, padding + h);
    fillPath.lineTo(points.first.dx, padding + h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);

    final dotRadius = size.width * 0.055;
    final hlRadius = size.width * 0.025;

    for (final pt in points) {
      canvas.drawCircle(pt, dotRadius, dotPaint);
      canvas.drawCircle(Offset(pt.dx - hlRadius * 0.3, pt.dy - hlRadius * 0.3), hlRadius, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineGraphPainter oldDelegate) => oldDelegate.color != color;
}
