import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class RatneshFallback extends StatelessWidget {
  final double logoSize;
  final double? width;
  final double? height;

  const RatneshFallback({
    super.key,
    required this.logoSize,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: context.colorPalette.goldLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/ratnesh-logo.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            color: context.colorPalette.goldDark,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(height: 4),
          Text(
            'RATNESHGOLD',
            style: GoogleFonts.bodoniModa(
              fontSize: logoSize * 0.18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: context.colorPalette.goldDark,
            ),
          ),
        ],
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    return SizedBox.expand(child: fallback);
  }
}
