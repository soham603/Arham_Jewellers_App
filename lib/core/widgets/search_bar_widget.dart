import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class SearchBarWidget extends StatelessWidget {
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

  static const _goldDark = Color(0xFF8B6914);
  static const _barColor = Color(0xFFF6F3EF);

  @override
  Widget build(BuildContext context) {
    final isTransparentOuter = outerBackgroundColor == Colors.transparent;
    final isTransparentBar = barBackgroundColor == Colors.transparent;

    final iconSize = context.responsiveWidth(20, tabletVal: 24);
    final smallIconSize = context.responsiveWidth(18, tabletVal: 22);
    final filterIconSize = context.responsiveWidth(22, tabletVal: 26);
    final hPad = context.responsiveWidth(16, tabletVal: 20);
    final vPad = context.responsiveWidth(10, tabletVal: 12);
    final spacing = context.responsiveWidth(10, tabletVal: 12);
    final textSize = context.responsiveWidth(15, tabletVal: 17);
    final hintSize = context.responsiveWidth(14, tabletVal: 16);
    final badgeFontSize = context.responsiveWidth(9, tabletVal: 10);
    const pillRadius = 50.0;

    return Container(
      padding: isTransparentOuter ? EdgeInsets.zero : EdgeInsets.fromLTRB(hPad, vPad * 0.8, hPad * 0.5, vPad * 0.8),
      decoration: BoxDecoration(
        color: outerBackgroundColor ?? Colors.white,
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Padding(
                padding: EdgeInsets.only(right: spacing * 0.8),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: iconSize,
                  color: _goldDark,
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(pillRadius),
                color: barBackgroundColor ?? _barColor,
                border: isTransparentBar
                    ? null
                    : Border.all(
                        color: _goldDark.withOpacity(0.2),
                        width: 1,
                      ),
                boxShadow: showShadow
                    ? [
                        BoxShadow(
                          color: _goldDark.withOpacity(0.06),
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
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      style: TextStyle(
                        fontSize: textSize,
                        color: const Color(0xFF000000),
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
                        hintText: hintText ?? 'Search gold, diamonds, rings...',
                        hintStyle: TextStyle(
                          fontSize: hintSize,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9590),
                        ),
                      ),
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  if (controller.text.isNotEmpty && onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: iconSize,
                        color: _goldDark,
                      ),
                    )
                  else if (showScanner)
                    GestureDetector(
                      onTap: onScannerTap,
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
          if (onFilterTap != null) ...[
            SizedBox(width: spacing * 0.8),
            GestureDetector(
              onTap: onFilterTap,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(spacing * 0.8),
                    child: Icon(
                      Icons.tune_rounded,
                      size: filterIconSize,
                      color: filterActiveCount > 0
                          ? _goldDark
                          : _goldDark.withOpacity(0.6),
                    ),
                  ),
                  if (filterActiveCount > 0)
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
                          '$filterActiveCount',
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
