import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../theme/app_colors.dart';

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

  static const Color _selectedBgColor = Color(0xFFE0DAD2);
  static const Color _unselectedBgColor = Color(0xFFF2EEEA);
  static const Color _unselectedContentColor = Color(0xFF847B71);

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

    final barHeight = context.responsiveWidth(66, tabletVal: 72);
    final iconContainerSize = context.responsiveWidth(36, tabletVal: 40);
    final iconSize = context.responsiveWidth(20, tabletVal: 22);
    final labelFontSize = context.responsiveWidth(11, tabletVal: 12);
    final itemVerticalPadding = context.responsiveWidth(6, tabletVal: 8);
    final iconLabelSpacing = context.responsiveWidth(4, tabletVal: 5);
    final inkwellBorderRadius = context.responsiveWidth(14, tabletVal: 16);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: barHeight),
        child: Row(
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
              iconContainerSize: iconContainerSize,
              iconSize: iconSize,
              labelFontSize: labelFontSize,
              itemVerticalPadding: itemVerticalPadding,
              iconLabelSpacing: iconLabelSpacing,
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
    required this.iconContainerSize,
    required this.iconSize,
    required this.labelFontSize,
    required this.itemVerticalPadding,
    required this.iconLabelSpacing,
    required this.inkwellBorderRadius,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDuration;
  final double iconContainerSize;
  final double iconSize;
  final double labelFontSize;
  final double itemVerticalPadding;
  final double iconLabelSpacing;
  final double inkwellBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: item.label,
        selected: isSelected,
        button: true,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(inkwellBorderRadius),
          child: AnimatedContainer(
            duration: animationDuration,
            padding: EdgeInsets.symmetric(
              vertical: itemVerticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedIconBubble(
                  icon: item.icon,
                  isSelected: isSelected,
                  animationDuration: animationDuration,
                  containerSize: iconContainerSize,
                  iconSize: iconSize,
                ),
                SizedBox(height: iconLabelSpacing),
                _AnimatedLabel(
                  label: item.label,
                  isSelected: isSelected,
                  animationDuration: animationDuration,
                  fontSize: labelFontSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedIconBubble extends StatelessWidget {
  const _AnimatedIconBubble({
    required this.icon,
    required this.isSelected,
    required this.animationDuration,
    required this.containerSize,
    required this.iconSize,
  });

  final IconData icon;
  final bool isSelected;
  final Duration animationDuration;
  final double containerSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppBottomNav._selectedBgColor
            : AppBottomNav._unselectedBgColor,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: isSelected
            ? AppColors.textDark
            : AppBottomNav._unselectedContentColor,
      ),
    );
  }
}

class _AnimatedLabel extends StatelessWidget {
  const _AnimatedLabel({
    required this.label,
    required this.isSelected,
    required this.animationDuration,
    required this.fontSize,
  });

  final String label;
  final bool isSelected;
  final Duration animationDuration;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: animationDuration,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? AppColors.textDark
            : AppBottomNav._unselectedContentColor,
      ),
      child: Text(label),
    );
  }
}
