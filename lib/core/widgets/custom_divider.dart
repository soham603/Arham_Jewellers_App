import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class JewelleryDivider extends StatelessWidget {
  final String? label;

  const JewelleryDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24, // Added a bit more breathing room on the edges
        vertical: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Left Fading Line ---
          Expanded(
            child: Container(
              height: 1.0, // Ultra-thin for elegance
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colorPalette.gold.withOpacity(0.6),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                label!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5, // Wide letter spacing looks premium
                  color: context.colorPalette.goldDeep,
                ),
              ),
            ),
          ] else ...[
            // 2. Icon Mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTinyDiamond(context),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.diamond_outlined,
                    size: 18,
                    color: context.colorPalette.goldDeep,
                  ),
                  const SizedBox(width: 8),
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
                    context.colorPalette.gold.withOpacity(0.6),
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
    return Transform.rotate(
      angle: math.pi / 4, // Rotates 45 degrees
      child: Container(
        width: 4.5,
        height: 4.5,
        decoration: BoxDecoration(
          color: context.colorPalette.gold.withOpacity(0.7),
        ),
      ),
    );
  }
}
