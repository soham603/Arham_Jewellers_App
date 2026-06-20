import 'package:flutter/material.dart';

class NavBarSpacer extends StatelessWidget {
  const NavBarSpacer({super.key});

  /// Returns the exact total visual height of [AppBottomNav],
  /// including the center logo overflow above the bar.
  static double heightOf(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.shortestSide >= 600;
    final barHeight = isLargeScreen ? 100.0 : 68.0;
    final bubbleSize = isLargeScreen ? 50.0 : 36.0;
    const barPaddingTop = 2.0;
    const barPaddingBottom = 4.0;
    const itemBoxHeight = 48.0;
    const bubbleBottomOffset = 16.0;
    final effectiveBubbleSize = bubbleSize + 12.0;
    final bubbleContainerHeight = effectiveBubbleSize + 6.0;

    final availableHeight = barHeight - barPaddingTop - barPaddingBottom;
    final itemTopOffset = (availableHeight - itemBoxHeight) / 2.0;
    final bubbleOverflowAboveItemBox =
        (bubbleBottomOffset + bubbleContainerHeight) - itemBoxHeight;
    final overflowAboveBar = bubbleOverflowAboveItemBox - itemTopOffset;

    return barHeight + 8.0 + (overflowAboveBar > 0 ? overflowAboveBar : 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: heightOf(context));
  }
}
