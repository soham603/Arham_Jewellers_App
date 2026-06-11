import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CategoryDivider extends StatelessWidget {
  final double vertical;

  const CategoryDivider({super.key, this.vertical = 16});

  @override
  Widget build(BuildContext context) {
    final hp = context.responsiveWidth(24, tabletVal: 32, largeTabletVal: 48);
    final spacing = context.responsiveWidth(8, tabletVal: 10, largeTabletVal: 14);
    final dotSize = context.responsiveWidth(4, tabletVal: 5, largeTabletVal: 7);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hp,
        vertical: vertical,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colorPalette.gold.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: context.colorPalette.gold.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colorPalette.gold.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionsDivider extends StatelessWidget {
  final String? label;
  final double vertical;

  const CollectionsDivider({super.key, this.label, this.vertical = 16});

  @override
  Widget build(BuildContext context) {
    final hp = context.responsiveWidth(24, tabletVal: 32, largeTabletVal: 48);
    final spacing = context.responsiveWidth(8, tabletVal: 10, largeTabletVal: 14);
    final labelSpacing = context.responsiveWidth(12, tabletVal: 16, largeTabletVal: 24);
    final iconSize = context.responsiveWidth(14, tabletVal: 18, largeTabletVal: 26);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hp,
        vertical: vertical,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colorPalette.gold.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          if (label != null && label!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: labelSpacing),
              child: Text(
                label!.toUpperCase(),
                style: TextStyle(
                  fontSize: context.responsiveFont(14, tabletMultiplier: 1.3, largeTabletMultiplier: 1.6),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ] else ...[
            SizedBox(width: spacing),
            Icon(
              Icons.diamond_outlined,
              size: iconSize,
              color: Colors.white70,
            ),
            SizedBox(width: spacing),
          ],
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colorPalette.gold.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JewelleryDivider extends StatelessWidget {
  final String? label;
  final double vertical;

  const JewelleryDivider({super.key, this.label, this.vertical = 20});

  @override
  Widget build(BuildContext context) {
    final hp = context.responsiveWidth(24, tabletVal: 32, largeTabletVal: 48);
    final spacing = context.responsiveWidth(8, tabletVal: 10, largeTabletVal: 14);
    final labelSpacing = context.responsiveWidth(16, tabletVal: 20, largeTabletVal: 30);
    final iconSpacing = context.responsiveWidth(12, tabletVal: 16, largeTabletVal: 24);
    final iconSize = context.responsiveWidth(18, tabletVal: 22, largeTabletVal: 32);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hp,
        vertical: vertical,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Left Fading Line ---
          Expanded(
            child: Container(
              height: 1.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colorPalette.gold.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // --- Central Element ---
          if (label != null && label!.isNotEmpty) ...[
            // 1. Label Mode (Centered)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: labelSpacing),
              child: Text(
                label!.toUpperCase(),
                style: TextStyle(
                  fontSize: context.responsiveFont(16, tabletMultiplier: 1.3, largeTabletMultiplier: 1.6),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ] else ...[
            // 2. Icon Mode
            Padding(
              padding: EdgeInsets.symmetric(horizontal: iconSpacing),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTinyDiamond(context),
                  SizedBox(width: spacing),
                  Icon(
                    Icons.diamond_outlined,
                    size: iconSize,
                    color: context.colorPalette.goldDeep,
                  ),
                  SizedBox(width: spacing),
                  _buildTinyDiamond(context),
                ],
              ),
            ),
          ],

          // --- Right Fading Line ---
          Expanded(
            child: Container(
              height: 1.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colorPalette.gold.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to create a tiny rotated square (diamond shape)
  Widget _buildTinyDiamond(BuildContext context) {
    final size = context.responsiveWidth(4.5, tabletVal: 6, largeTabletVal: 9);
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.colorPalette.gold.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
