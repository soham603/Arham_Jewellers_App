import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import 'logo_widget.dart';

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
      child: Center(
        child: LogoWidget(
          logoSize: logoSize,
          showSubtitle: false,
          iconColor: context.colorPalette.goldDark,
          nameColor: context.colorPalette.goldDark,
          nameLetterSpacing: 1,
          iconNameSpacing: 4,
        ),
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    return SizedBox.expand(child: fallback);
  }
}
