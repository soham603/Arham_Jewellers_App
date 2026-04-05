import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CarouselShimmer extends StatelessWidget {
  const CarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Shimmer.fromColors(
      baseColor: palette.shimmerBaseColor,
      highlightColor: palette.shimmerHighLightColor,
      child: Container(
        width: double.infinity,
        height: context.getScreenHeight(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}