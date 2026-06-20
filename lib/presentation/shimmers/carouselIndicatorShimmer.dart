import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CarouselIndicatorShimmer extends StatelessWidget {
  const CarouselIndicatorShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final active = i == 0;

          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: context.responsiveWidth(active ? 22 : 6, tabletVal: active ? 36 : 10),
              height: context.responsiveWidth(6, tabletVal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
