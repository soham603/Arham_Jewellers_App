import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../presentation/controllers/CategoryController.dart';
import '../../presentation/controllers/navigation_controller.dart';

class HomeSearchBar extends StatefulWidget {
  final VoidCallback? onScannerTap;
  final CategoryController? categoryController;

  const HomeSearchBar({
    super.key,
    this.onScannerTap,
    this.categoryController,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  Timer? _timer;
  int _currentIndex = 0;

  static String _cleanCategoryName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
  }

  List<String> _extractCategoryNames(CategoryController controller) {
    final all = <CategoryModel>[
      ...controller.k18Categories,
      ...controller.k20Categories,
      ...controller.k22Categories,
    ];
    final seen = <String>{};
    final names = <String>[];
    for (final cat in all) {
      final cleaned = _cleanCategoryName(cat.name);
      if (cleaned.isNotEmpty && seen.add(cleaned.toLowerCase())) {
        names.add(cleaned);
      }
    }
    names.shuffle();
    return names;
  }

  void _startTimer(List<String> names) {
    _timer?.cancel();
    if (names.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _currentIndex++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = context.responsiveWidth(20, tabletVal: 30);
    final smallIconSize = context.responsiveWidth(18, tabletVal: 26);
    final spacing = context.responsiveWidth(12, tabletVal: 16);
    final hPad = context.responsiveWidth(14, tabletVal: 24);
    final vPad = context.responsiveWidth(7, tabletVal: 12);
    final fontSize = context.responsiveWidth(14, tabletVal: 19);
    final stackHeight = context.responsiveWidth(20, tabletVal: 30);

    final categoryController = widget.categoryController ?? Get.find<CategoryController>();

    return GestureDetector(
      onTap: () {
        Get.find<NavigationController>().switchTab(1);
      },

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: const Color(0xFFF5F1EC),
          border: Border.all(
            color: context.colorPalette.gold.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorPalette.gold.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.colorPalette.goldDark,
              size: iconSize,
            ),

            SizedBox(width: spacing),

            Expanded(
              child: Obx(() {
                final names = _extractCategoryNames(categoryController);

                if (names.isEmpty) {
                  return Text(
                    'Search',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9E9590),
                    ),
                  );
                }

                if (_timer == null || !_timer!.isActive) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _startTimer(names);
                  });
                }

                final currentName = names[_currentIndex % names.length];

                return SizedBox(
                  height: stackHeight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Align(
                      key: ValueKey(currentName),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        currentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9590),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (widget.onScannerTap != null)
              GestureDetector(
                onTap: widget.onScannerTap,
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: context.colorPalette.goldDark,
                  size: smallIconSize,
                ),
              )
            else
              Icon(
                Icons.qr_code_scanner_rounded,
                color: context.colorPalette.goldDark,
                size: smallIconSize,
              ),
          ],
        ),
      ),
    );
  }
}
