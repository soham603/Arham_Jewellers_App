import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../app/routes/app_routes.dart';
import '../../presentation/controllers/CategoryController.dart';
import '../../presentation/controllers/navigation_controller.dart';

class HomeSearchBar extends StatefulWidget {
  final VoidCallback? onScannerTap;

  const HomeSearchBar({
    super.key,
    this.onScannerTap,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  Timer? _timer;
  int _currentIndex = 0;
  List<String> _categoryNames = [];
  String _currentCategoryName = '';

  @override
  void initState() {
    super.initState();
    _refreshCategories();
    _startTimer();
  }

  void _refreshCategories() {
    final names = _extractCategoryNames();
    if (names.isNotEmpty) {
      _categoryNames = names;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_categoryNames.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _refreshCategories();
      setState(() => _pickNextPlaceholder());
    });
  }

  static String _cleanCategoryName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
  }

  List<String> _extractCategoryNames() {
    final controller = Get.find<CategoryController>();
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

  void _pickNextPlaceholder() {
    if (_categoryNames.isNotEmpty) {
      _currentCategoryName = _categoryNames[_currentIndex % _categoryNames.length];
      _currentIndex++;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = context.responsiveWidth(20, tabletVal: 24);
    final smallIconSize = context.responsiveWidth(18, tabletVal: 22);
    final spacing = context.responsiveWidth(12, tabletVal: 14);
    final hPad = context.responsiveWidth(14, tabletVal: 18);
    final vPad = context.responsiveWidth(5, tabletVal: 7);
    final fontSize = context.responsiveWidth(14, tabletVal: 16);
    final stackHeight = context.responsiveWidth(20, tabletVal: 24);
    final searchTextWidth = context.getScreenWidth(14);

    return GestureDetector(
      onTap: () {
        try {
          Get.find<NavigationController>().switchTab(AppRoutes.tabIndexSearch);
        } catch (_) {
          Get.toNamed(AppRoutes.search);
        }
      },

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: const Color(0xFFF5F1EC),
          border: Border.all(
            color: context.colorPalette.gold.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorPalette.gold.withOpacity(0.06),
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
              child: _categoryNames.isNotEmpty
                  ? SizedBox(
                      height: stackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Text(
                              'Search ',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF9E9590),
                              ),
                            ),
                          ),
                          Positioned(
                            left: searchTextWidth,
                            top: 0,
                            bottom: 0,
                            right: 0,
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
                                key: ValueKey(_currentCategoryName),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _currentCategoryName,
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
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'Search',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9E9590),
                      ),
                    ),
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