import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/ContextExtensions.dart';

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.heightPercent(12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, _) =>
            SizedBox(width: context.getResponsiveSize(3)),
        itemBuilder: (_, _) {
          return Shimmer.fromColors(
            baseColor: context.colorPalette.shimmerBaseColor,
            highlightColor: context.colorPalette.shimmerHighLightColor,
            child: Container(
              width: context.getResponsiveSize(18),
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(0.8),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    width: context.getResponsiveSize(11),
                    height: context.heightPercent(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.6)),
                  Container(
                    width: context.getResponsiveSize(10),
                    height: context.heightPercent(1.2),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}