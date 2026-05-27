import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class JewelleryDivider extends StatelessWidget {
  final String? label;

  const JewelleryDivider({
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colorPalette.gold.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  context.colorPalette.goldLight,
                  context.colorPalette.gold,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colorPalette.gold
                      .withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.diamond_outlined,
                  size: 20,
                  color: Colors.white.withOpacity(0.9),
                ),

                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colorPalette.gold
                        .withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          if (label != null) ...[
            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: context.colorPalette.goldLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: context.colorPalette.gold
                      .withOpacity(0.3),
                ),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: context.colorPalette.goldDeep,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}