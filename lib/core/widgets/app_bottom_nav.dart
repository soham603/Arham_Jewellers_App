import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  static const Duration _animationDuration = Duration(milliseconds: 220);
  static const Curve _animationCurve = Curves.easeOutCubic;
  static const double _maxContentWidth = 720;

  static const List<_NavItem> _userItems = [
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Search', icon: Icons.search_rounded),
    _NavItem(label: 'Cart', icon: Icons.shopping_cart_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  static const List<_NavItem> _adminItems = [
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Search', icon: Icons.search_rounded),
    _NavItem(label: 'Share', icon: Icons.share_rounded),
    _NavItem(label: 'Admin', icon: Icons.admin_panel_settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _userItems;

    assert(
      currentIndex >= 0 && currentIndex < items.length,
      'currentIndex must be between 0 and ${items.length - 1}, but got $currentIndex.',
    );

    final safeIndex =
        currentIndex >= 0 && currentIndex < items.length ? currentIndex : 0;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.shortestSide >= 600;

    final barHeight = isLargeScreen ? 80.0 : 72.0;
    final bubbleSize = isLargeScreen ? 42.0 : 36.0;
    final iconSize = isLargeScreen ? 22.0 : 20.0;
    final labelFontSize = isLargeScreen ? 13.0 : 12.0;

    final unselectedBubbleColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(
        theme.brightness == Brightness.dark ? 0.14 : 0.05,
      ),
      colorScheme.surface,
    );

    return SizedBox(
      height: barHeight,
      child: Material(
        color: colorScheme.surface,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(
          theme.brightness == Brightness.dark ? 0.24 : 0.08,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withOpacity(0.10),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = index == safeIndex;

                      return _NavItemTile(
                        item: item,
                        index: index,
                        totalCount: items.length,
                        isSelected: isSelected,
                        onTap: () {
                          if (isSelected) {
                            // Optional UX enhancement:
                            // trigger scroll-to-top or pop-to-root here.
                            return;
                          }

                          HapticFeedback.selectionClick();
                          onTap(index);
                        },
                        animationDuration: _animationDuration,
                        animationCurve: _animationCurve,
                        bubbleSize: bubbleSize,
                        iconSize: iconSize,
                        labelFontSize: labelFontSize,
                        selectedBubbleColor: colorScheme.primary,
                        unselectedBubbleColor: unselectedBubbleColor,
                        selectedIconColor: colorScheme.onPrimary,
                        selectedLabelColor: colorScheme.primary,
                        unselectedContentColor: colorScheme.onSurfaceVariant,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.index,
    required this.totalCount,
    required this.isSelected,
    required this.onTap,
    required this.animationDuration,
    required this.animationCurve,
    required this.bubbleSize,
    required this.iconSize,
    required this.labelFontSize,
    required this.selectedBubbleColor,
    required this.unselectedBubbleColor,
    required this.selectedIconColor,
    required this.selectedLabelColor,
    required this.unselectedContentColor,
  });

  final _NavItem item;
  final int index;
  final int totalCount;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDuration;
  final Curve animationCurve;
  final double bubbleSize;
  final double iconSize;
  final double labelFontSize;
  final Color selectedBubbleColor;
  final Color unselectedBubbleColor;
  final Color selectedIconColor;
  final Color selectedLabelColor;
  final Color unselectedContentColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);

    return Expanded(
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 500),
        child: Semantics(
          label: '${item.label}, tab ${index + 1} of $totalCount',
          hint: isSelected ? 'Current tab' : 'Double tap to open',
          selected: isSelected,
          button: true,
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              mouseCursor: SystemMouseCursors.click,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: (isSelected ? selectedIconColor : unselectedContentColor).withOpacity(0.03),
              focusColor: (isSelected ? selectedIconColor : unselectedContentColor).withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        duration: animationDuration,
                        curve: animationCurve,
                        scale: isSelected ? 1.0 : 0.96,
                        child: AnimatedContainer(
                          duration: animationDuration,
                          curve: animationCurve,
                          width: bubbleSize,
                          height: bubbleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? selectedBubbleColor
                                : unselectedBubbleColor,
                          ),
                          child: Icon(
                            item.icon,
                            size: iconSize,
                            color: isSelected
                                ? selectedIconColor
                                : unselectedContentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: bubbleSize + 24,
                        child: AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          curve: animationCurve,
                          style: TextStyle(
                            fontSize: labelFontSize,
                            height: 1.1,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? selectedLabelColor
                                : unselectedContentColor,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
