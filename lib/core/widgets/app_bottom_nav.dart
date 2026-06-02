import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const double _barHeight = 66.0;
  static const double _iconContainerSize = 36.0;
  static const double _iconSize = 20.0;
  static const double _labelFontSize = 11.0;
  static const double _itemVerticalPadding = 6.0;
  static const double _iconLabelSpacing = 4.0;
  static const Duration _animationDuration = Duration(milliseconds: 220);
  static const double _inkwellBorderRadius = 14.0;

  static const Color _selectedBgColor = Color(0xFFE0DAD2);
  static const Color _unselectedBgColor = Color(0xFFF2EEEA);
  static const Color _unselectedContentColor = Color(0xFF847B71);

  List<_NavItem> get _navItems => [
    const _NavItem(label: 'Home', icon: Icons.home_rounded),
    const _NavItem(label: 'Search', icon: Icons.search_rounded),
    const _NavItem(label: 'Cart', icon: Icons.shopping_cart_rounded),
    _NavItem(label: isAdmin ? 'Admin' : 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    assert(
      currentIndex >= 0 && currentIndex < _navItems.length,
      'currentIndex must be between 0 and ${_navItems.length - 1}, '
      'but got $currentIndex.',
    );

    return Container(
      height: _barHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
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
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDuration;

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
          borderRadius: BorderRadius.circular(AppBottomNav._inkwellBorderRadius),
          child: AnimatedContainer(
            duration: animationDuration,
            padding: const EdgeInsets.symmetric(
              vertical: AppBottomNav._itemVerticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedIconBubble(
                  icon: item.icon,
                  isSelected: isSelected,
                  animationDuration: animationDuration,
                ),
                const SizedBox(height: AppBottomNav._iconLabelSpacing),
                _AnimatedLabel(
                  label: item.label,
                  isSelected: isSelected,
                  animationDuration: animationDuration,
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
  });

  final IconData icon;
  final bool isSelected;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      width: AppBottomNav._iconContainerSize,
      height: AppBottomNav._iconContainerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppBottomNav._selectedBgColor
            : AppBottomNav._unselectedBgColor,
      ),
      child: Icon(
        icon,
        size: AppBottomNav._iconSize,
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
  });

  final String label;
  final bool isSelected;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: animationDuration,
      style: TextStyle(
        fontSize: AppBottomNav._labelFontSize,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? AppColors.textDark
            : AppBottomNav._unselectedContentColor,
      ),
      child: Text(label),
    );
  }
}
