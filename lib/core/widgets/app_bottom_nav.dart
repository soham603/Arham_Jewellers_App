import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:picons/picons.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    this.icon,
    this.selectedIcon,
    this.assetPath,
    this.isCenter = false,
  }) : assert(
          assetPath != null || (icon != null && selectedIcon != null),
          'Provide either assetPath or both icon and selectedIcon.',
        );

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? assetPath;
  final bool isCenter;
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
    _NavItem(
      label: 'Home',
      icon: PiconsRegular.house,
      selectedIcon: PiconsRegular.house,
    ),
    _NavItem(
      label: 'Search',
      icon: PiconsRegular.magnifyingGlass,
      selectedIcon: PiconsRegular.magnifyingGlass,
    ),
    _NavItem(
      label: 'Catalog',
      assetPath: 'assets/images/ratnesh-logo-opt.webp',
      isCenter: true,
    ),
    _NavItem(
      label: 'Cart',
      icon: PiconsRegular.shoppingCart,
      selectedIcon: PiconsRegular.shoppingCart,
    ),
    _NavItem(
      label: 'Profile',
      icon: PiconsRegular.user,
      selectedIcon: PiconsRegular.user,
    ),
  ];

  static const List<_NavItem> _adminItems = [
    _NavItem(
      label: 'Home',
      icon: PiconsRegular.house,
      selectedIcon: PiconsRegular.house,
    ),
    _NavItem(
      label: 'Search',
      icon: PiconsRegular.magnifyingGlass,
      selectedIcon: PiconsRegular.magnifyingGlass,
    ),
    _NavItem(
      label: 'Catalog',
      assetPath: 'assets/images/ratnesh-logo-opt.webp',
      isCenter: true,
    ),
    _NavItem(
      label: 'Share',
      icon: PiconsRegular.share,
      selectedIcon: PiconsRegular.share,
    ),
    _NavItem(
      label: 'Admin',
      icon: PiconsRegular.gearSix,
      selectedIcon: PiconsRegular.gearSix,
    ),
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

    final barHeight = isLargeScreen ? 100.0 : 68.0;
    final bubbleSize = isLargeScreen ? 50.0 : 36.0;
    final iconSize = isLargeScreen ? 32.0 : 24.0;
    final labelFontSize = isLargeScreen ? 14.0 : 11.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        height: barHeight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
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
                        if (isSelected) return;

                        HapticFeedback.selectionClick();
                        onTap(index);
                      },
                      animationDuration: _animationDuration,
                      animationCurve: _animationCurve,
                      bubbleSize: bubbleSize,
                      iconSize: iconSize,
                      labelFontSize: labelFontSize,
                      selectedBubbleColor:
                          context.colorPalette.goldDark.withValues(alpha: 0.06),
                      unselectedBubbleColor: Colors.transparent,
                      selectedIconColor: context.colorPalette.goldDark,
                      selectedLabelColor: context.colorPalette.goldDark,
                      unselectedIconColor: Colors.black.withValues(alpha: 0.65),
                      unselectedLabelColor: Colors.black.withValues(alpha: 0.65),
                    );
                  }),
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
    required this.unselectedIconColor,
    required this.unselectedLabelColor,
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
  final Color unselectedIconColor;
  final Color unselectedLabelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isCenterItem = item.isCenter && item.assetPath != null;
    final borderRadius = BorderRadius.circular(isCenterItem ? 26 : 20);
    final effectiveBubbleSize = isCenterItem ? bubbleSize + 12 : bubbleSize;

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
              hoverColor:
                  (isSelected ? selectedIconColor : unselectedLabelColor)
                      .withValues(alpha: 0.03),
              focusColor:
                  (isSelected ? selectedIconColor : unselectedLabelColor)
                      .withValues(alpha: 0.05),
child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCenterItem ? 2 : 4,
                  vertical: 0,
                ),
                child: SizedBox(
                  width: effectiveBubbleSize + 24,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: isCenterItem ? 16 : 12,
                      child: AnimatedScale(
                        duration: animationDuration,
                        curve: animationCurve,
                        scale: isSelected ? 1.0 : (isCenterItem ? 0.98 : 0.96),
                        child: isCenterItem
                            ? Container(
                                width: effectiveBubbleSize + 6,
                                height: effectiveBubbleSize + 6,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: context.colorPalette.goldDark,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: theme.brightness == Brightness.dark
                                            ? 0.22
                                            : 0.10,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: AnimatedContainer(
                                  duration: animationDuration,
                                  curve: animationCurve,
                                  width: effectiveBubbleSize,
                                  height: effectiveBubbleSize,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.colorPalette.goldDark,
                                  ),
                                  child: Image.asset(
                                    item.assetPath!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    color: context.colorPalette.cream,
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                              )
                            : AnimatedContainer(
                                duration: animationDuration,
                                curve: animationCurve,
                                width: effectiveBubbleSize,
                                height: effectiveBubbleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? selectedBubbleColor
                                      : unselectedBubbleColor,
                                ),
                                child: Icon(
                                  isSelected
                                      ? item.selectedIcon
                                      : item.icon,
                                  size: iconSize,
                                  color: isSelected
                                      ? selectedIconColor
                                      : unselectedIconColor,
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: SizedBox(
                          width: effectiveBubbleSize + 24,
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
                                  : unselectedLabelColor,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
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
