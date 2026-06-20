import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CarouselIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const CarouselIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (i) {
          final active = i == currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: context.responsiveWidth(active ? 22 : 6, tabletVal: active ? 36 : 10),
            height: context.responsiveWidth(6, tabletVal: 12),
            decoration: BoxDecoration(
              color: active
                  ? context.colorPalette.gold
                  : context.colorPalette.border,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
