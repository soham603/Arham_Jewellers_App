import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AdminOrderShimmer extends StatelessWidget {
  const AdminOrderShimmer({
    super.key,
    this.showPagination = false,
    this.showTopFilter = false,
  });

  final bool showPagination;
  final bool showTopFilter;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        if (!showPagination)
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,

            highlightColor: Colors.grey.shade100,

            child: Container(
              height: 70,

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

        const SizedBox(height: 18),

        ...List.generate(
          3,

          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),

            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,

              highlightColor: Colors.grey.shade100,

              child: Container(
                height: 135,

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
