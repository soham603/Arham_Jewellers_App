import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio,
    this.phoneColumns = 2,
    this.tabletColumns = 3,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final double? childAspectRatio;
  final int phoneColumns;
  final int tabletColumns;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width >= 600;
    final columns = isTablet ? tabletColumns : phoneColumns;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing ?? 8,
        crossAxisSpacing: crossAxisSpacing ?? 8,
        childAspectRatio: childAspectRatio ?? (columns == 2 ? 0.66 : 0.72),
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
