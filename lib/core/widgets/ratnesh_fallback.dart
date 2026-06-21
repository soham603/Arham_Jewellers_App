import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import 'logo_widget.dart';

class RatneshFallback extends StatelessWidget {
  final double logoSize;
  final double nameFontSize;
  final double? width;
  final double? height;

  const RatneshFallback({
    super.key,
    required this.logoSize,
    this.nameFontSize = 6,
    this.width,
    this.height,
  });

  const RatneshFallback.xs({
    super.key,
    this.width,
    this.height,
  })  : logoSize = 12, // Reduced from 16
        nameFontSize = 4;

  const RatneshFallback.s({
    super.key,
    this.width,
    this.height,
  })  : logoSize = 18, // Reduced from 24
        nameFontSize = 6;

  const RatneshFallback.m({
    super.key,
    this.width,
    this.height,
  })  : logoSize = 32, // Reduced from 44
        nameFontSize = 10;

  const RatneshFallback.l({
    super.key,
    this.width,
    this.height,
  })  : logoSize = 56, // Reduced from 72
        nameFontSize = 14;

  const RatneshFallback.xl({
    super.key,
    this.width,
    this.height,
  })  : logoSize = 80, // Reduced from 96
        nameFontSize = 18;

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.of(context).size.shortestSide / 375).clamp(1.0, 2.0);

    final fallback = Container(
      color: context.colorPalette.goldLight,
      child: Center(
        child: LogoWidget(
          logoSize: logoSize * scale,
          showSubtitle: false,
          iconColor: context.colorPalette.goldDark,
          nameColor: context.colorPalette.goldDark,
          nameLetterSpacing: 0.5,
          iconNameSpacing: 4 * scale,
          nameFontSize: nameFontSize * scale,
        ),
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    return SizedBox.expand(child: fallback);
  }
}