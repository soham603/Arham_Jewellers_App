import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..color = AppColors.primaryGold;
    canvas.drawCircle(center, radius * 0.98, ring);

    final branchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.011
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8C663B);

    final branchPath = Path()
      ..moveTo(center.dx - radius * 0.68, center.dy + radius * 0.45)
      ..quadraticBezierTo(center.dx - radius * 0.25, center.dy + radius * 0.05, center.dx + radius * 0.05, center.dy - radius * 0.18)
      ..quadraticBezierTo(center.dx + radius * 0.28, center.dy - radius * 0.35, center.dx + radius * 0.62, center.dy - radius * 0.52);
    canvas.drawPath(branchPath, branchPaint);

    final branchPath2 = Path()
      ..moveTo(center.dx - radius * 0.58, center.dy - radius * 0.08)
      ..quadraticBezierTo(center.dx - radius * 0.2, center.dy - radius * 0.32, center.dx + radius * 0.56, center.dy - radius * 0.1);
    canvas.drawPath(branchPath2, branchPaint);

    final branchPath3 = Path()
      ..moveTo(center.dx - radius * 0.46, center.dy + radius * 0.56)
      ..quadraticBezierTo(center.dx + radius * 0.04, center.dy + radius * 0.32, center.dx + radius * 0.58, center.dy + radius * 0.44);
    canvas.drawPath(branchPath3, branchPaint);

    final leafPaint = Paint()..color = const Color(0xFF8C663B);
    final rnd = Random(17);
    for (var i = 0; i < 48; i++) {
      final angle = rnd.nextDouble() * 2 * pi;
      final r = radius * (0.18 + rnd.nextDouble() * 0.68);
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      final leafW = size.width * (0.06 + rnd.nextDouble() * 0.022);
      final leafH = size.width * (0.03 + rnd.nextDouble() * 0.015);

      final rect = Rect.fromCenter(center: Offset(x, y), width: leafW, height: leafH);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + pi / 8);
      canvas.translate(-x, -y);
      canvas.drawOval(rect, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
