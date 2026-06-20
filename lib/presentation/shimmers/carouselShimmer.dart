import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';

class CarouselShimmer extends StatelessWidget {
  const CarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.warmShimmerBase,
      highlightColor: AppColors.warmShimmerHighlight,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }
}
