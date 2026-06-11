import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../theme/app_colors.dart';

class _NavItem {
  const _NavItem({required this.label, required this.icon});

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

  // Exact theme colors paired with the floating capsule look
  static const Color _unselectedBgColor = Color(
    0xFFF2EEEA,
  ); // Light warm background
  static const Color _unselectedContentColor = Color(
    0xFF847B71,
  ); // Soft grey content
  static const Color _brandBrownColor = Color(
    0xFF3E2723,
  ); // Signature deep espresso brown
  static const Color _activeCapsuleColor = Color(
    0xFFEBDCCB,
  ); // Elegant cream-brown capsule tint

  List<_NavItem> get _navItems => [
    const _NavItem(label: 'Home', icon: Icons.home_rounded),
    const _NavItem(label: 'Search', icon: Icons.search_rounded),
    _NavItem(
      label: isAdmin ? 'Share' : 'Cart',
      icon: isAdmin ? Icons.share_rounded : Icons.shopping_cart_rounded,
    ),
    _NavItem(label: isAdmin ? 'Admin' : 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    assert(
      currentIndex >= 0 && currentIndex < _navItems.length,
      'currentIndex must be between 0 and ${_navItems.length - 1}, '
      'but got $currentIndex.',
    );

    final barHeight = context.getResponsiveSize(10.5);
    final labelFontSize = context.getResponsiveSize(2.3);
    final iconSize = context.getResponsiveSize(5.6);
    final inkwellBorderRadius = context.getResponsiveSize(4.0);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom + 4,
        left: 12,
        right: 12,
        top: 6,
      ),
      // Mimicking the exact rounded container card shape from image_0fdf5f.png
      decoration: const BoxDecoration(
        color: _unselectedBgColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28), // Beautifully curved lower terminal edge
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: barHeight),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _navItems.length,
            (index) => _NavItemTile(
              item: _navItems[index],
              isSelected: index == currentIndex,
              onTap: () {
                if (index == currentIndex) return;
                HapticFeedback.selectionClick();
                onTap(index);
              },
              animationDuration: _animationDuration,
              iconSize: iconSize,
              labelFontSize: labelFontSize,
              inkwellBorderRadius: inkwellBorderRadius,
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
    required this.isSelected,
    required this.onTap,
    required this.animationDuration,
    required this.iconSize,
    required this.labelFontSize,
    required this.inkwellBorderRadius,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDuration;
  final double iconSize;
  final double labelFontSize;
  final double inkwellBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        // Active capsule container padding vs standard raw item space
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 8.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppBottomNav._activeCapsuleColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            24,
          ), // Perfectly circular stadium border pill
        ),
        child: InkWell(
          onTap: onTap,
          highlightColor: Colors.transparent,
          splashColor: AppBottomNav._brandBrownColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(inkwellBorderRadius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: iconSize,
                color: isSelected
                    ? AppBottomNav
                          ._brandBrownColor // Deep brown active state
                    : AppBottomNav._unselectedContentColor,
              ),
              // Dynamic layout adjustment: only rendering the label string beside the icon if selected
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppBottomNav._brandBrownColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: isSelected
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: animationDuration,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
