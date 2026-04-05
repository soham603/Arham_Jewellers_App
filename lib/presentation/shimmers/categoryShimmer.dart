import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/ContextExtensions.dart';

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.getScreenHeight(12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) =>
            SizedBox(width: context.getScreenWidth(3)),
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: context.colorPalette.shimmerBaseColor,
            highlightColor: context.colorPalette.shimmerHighLightColor,
            child: Container(
              width: context.getScreenWidth(18),
              padding: EdgeInsets.symmetric(
                vertical: context.getScreenHeight(0.8),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    width: context.getScreenWidth(11),
                    height: context.getScreenHeight(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.6)),
                  Container(
                    width: context.getScreenWidth(10),
                    height: context.getScreenHeight(1.2),
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