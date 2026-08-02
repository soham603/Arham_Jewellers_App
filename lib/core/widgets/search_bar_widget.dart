import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../presentation/controllers/CategoryController.dart';
import '../utils/string_utils.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBack;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final VoidCallback? onScannerTap;
  final int filterActiveCount;
  final Color? outerBackgroundColor;
  final Color? barBackgroundColor;
  final String? hintText;
  final bool showShadow;
  final bool showScanner;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onBack,
    this.onClear,
    this.onFilterTap,
    this.onScannerTap,
    this.filterActiveCount = 0,
    this.outerBackgroundColor,
    this.barBackgroundColor,
    this.hintText,
    this.showShadow = true,
    this.showScanner = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  static const _goldDark = AppColors.primaryGoldDark;
  static const _barColor = AppColors.tileBg;

  Timer? _timer;
  int _currentIndex = 0;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();

    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _effectiveFocusNode.addListener(_handleRebuild);
    widget.controller.addListener(_handleRebuild);

    _loadCategoryNames();
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleRebuild);
      widget.controller.addListener(_handleRebuild);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      final oldFocusNode = oldWidget.focusNode ?? _internalFocusNode;
      oldFocusNode?.removeListener(_handleRebuild);

      if (oldWidget.focusNode == null && widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }

      if (widget.focusNode == null && _internalFocusNode == null) {
        _internalFocusNode = FocusNode();
      }

      _effectiveFocusNode.addListener(_handleRebuild);
    }
  }

  void _handleRebuild() {
    if (mounted) {
      setState(() {});
    }
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
      final cleaned = cleanCategoryName(cat.name);
      if (cleaned.isNotEmpty && seen.add(cleaned.toLowerCase())) {
        names.add(cleaned);
      }
    }

    names.shuffle();
    return names;
  }

  void _loadCategoryNames() {
    try {
      final categoryController = Get.find<CategoryController>();
      final names = _extractCategoryNames(categoryController);

      if (!mounted) return;

      _startTimer(names);
    } catch (e, st) {
      _timer?.cancel();
    }
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
    widget.controller.removeListener(_handleRebuild);
    _effectiveFocusNode.removeListener(_handleRebuild);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTransparentOuter =
        widget.outerBackgroundColor == Colors.transparent;
    final isTransparentBar = widget.barBackgroundColor == Colors.transparent;

    final iconSize = context.responsiveWidth(20, tabletVal: 30);
    final smallIconSize = context.responsiveWidth(18, tabletVal: 28);
    final filterIconSize = context.responsiveWidth(22, tabletVal: 32);
    final hPad = context.responsiveWidth(16, tabletVal: 28);
    final vPad = context.responsiveWidth(10, tabletVal: 16);
    final spacing = context.responsiveWidth(10, tabletVal: 16);
    final textSize = context.responsiveWidth(15, tabletVal: 22);
    final hintSize = context.responsiveWidth(14, tabletVal: 20);
    final badgeFontSize = context.responsiveWidth(9, tabletVal: 14);
    final stackHeight = context.responsiveWidth(20, tabletVal: 32);
    const pillRadius = 50.0;

    final showAnimatedHint =
        widget.controller.text.isEmpty && widget.hintText == null && !_effectiveFocusNode.hasFocus;

    return Container(
      padding: isTransparentOuter
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(hPad * 0.3, vPad * 0.8, hPad * 0.5, vPad * 0.8),
      decoration: BoxDecoration(
        color: widget.outerBackgroundColor ?? Colors.white,
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: EdgeInsets.all(spacing * 1),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: iconSize,
                    color: _goldDark,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(pillRadius),
                color: widget.barBackgroundColor ?? _barColor,
                border: isTransparentBar
                    ? null
                    : Border.all(
                        color: _goldDark.withValues(alpha: 0.2),
                        width: 1,
                      ),
                boxShadow: widget.showShadow
                    ? [
                        BoxShadow(
                          color: _goldDark.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: _goldDark,
                    size: iconSize,
                  ),
                  SizedBox(width: spacing),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            autofocus: widget.autofocus,
                            style: TextStyle(
                              fontSize: textSize,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              hintText: showAnimatedHint ? null : widget.hintText,
                              hintStyle: TextStyle(
                                fontSize: hintSize,
                                fontWeight: FontWeight.w400,
                                color: AppColors.hint,
                              ),
                            ),
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                          ),
                              if (showAnimatedHint)
                            IgnorePointer(
                              child: _AnimatedHint(
                                currentIndex: _currentIndex,
                                fontSize: hintSize,
                                stackHeight: stackHeight,
                                onNamesReady: _startTimer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (widget.controller.text.isNotEmpty &&
                      widget.onClear != null)
                    GestureDetector(
                      onTap: widget.onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: iconSize,
                        color: _goldDark,
                      ),
                    )
                  else if (widget.showScanner)
                    GestureDetector(
                      onTap: widget.onScannerTap,
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: _goldDark,
                        size: smallIconSize,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            SizedBox(width: spacing * 0.8),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(spacing * 0.8),
                    child: Icon(
                      Icons.tune_rounded,
                      size: filterIconSize,
                      color: widget.filterActiveCount > 0
                          ? _goldDark
                          : _goldDark.withValues(alpha: 0.6),
                    ),
                  ),
                  if (widget.filterActiveCount > 0)
                    Positioned(
                      top: spacing * 0.2,
                      right: spacing * 0.2,
                      child: Container(
                        padding: EdgeInsets.all(spacing * 0.35),
                        decoration: const BoxDecoration(
                          color: _goldDark,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.filterActiveCount}',
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedHint extends StatefulWidget {
  final int currentIndex;
  final double fontSize;
  final double stackHeight;
  final ValueChanged<List<String>> onNamesReady;

  const _AnimatedHint({
    required this.currentIndex,
    required this.fontSize,
    required this.stackHeight,
    required this.onNamesReady,
  });

  @override
  State<_AnimatedHint> createState() => _AnimatedHintState();
}

class _AnimatedHintState extends State<_AnimatedHint> {
  @override
  void initState() {
    super.initState();
    _initCategories();
  }

  void _initCategories() {
    try {
      final categoryController = Get.find<CategoryController>();
      final names = _extractCategoryNames(categoryController);
      if (names.isNotEmpty) {
        widget.onNamesReady(names);
      }
    } catch (e) {
    }
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
      final cleaned = cleanCategoryName(cat.name);
      if (cleaned.isNotEmpty && seen.add(cleaned.toLowerCase())) {
        names.add(cleaned);
      }
    }
    names.shuffle();
    return names;
  }

  @override
  Widget build(BuildContext context) {
    try {
      final categoryController = Get.find<CategoryController>();
      final names = _extractCategoryNames(categoryController);

      if (names.isEmpty) {
        return _buildStaticHint();
      }

      final currentName = names[widget.currentIndex % names.length];

      return SizedBox(
        height: widget.stackHeight,
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
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.hint,
              ),
            ),
          ),
        ),
      );
    } catch (e, st) {
      return _buildStaticHint();
    }
  }

  Widget _buildStaticHint() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'gold, diamonds, rings...',
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.hint,
        ),
      ),
    );
  }
}