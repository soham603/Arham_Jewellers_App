import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBack;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final int filterActiveCount;
  final Color? outerBackgroundColor;
  final Color? barBackgroundColor;
  final String? hintText;

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
    this.filterActiveCount = 0,
    this.outerBackgroundColor,
    this.barBackgroundColor,
    this.hintText,
  });

  static const _goldDark = Color(0xFF8B6914);
  static const _barColor = Color(0xFFF5F1EC);

  @override
  Widget build(BuildContext context) {
    final isTransparentOuter = outerBackgroundColor == Colors.transparent;
    final isTransparentBar = barBackgroundColor == Colors.transparent;

    return Container(
      padding: isTransparentOuter ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: outerBackgroundColor ?? Colors.white,
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: _goldDark,
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: barBackgroundColor ?? _barColor,
                border: isTransparentBar
                    ? null
                    : Border.all(
                        color: _goldDark.withOpacity(0.2),
                        width: 1,
                      ),
                boxShadow: isTransparentBar
                    ? null
                    : [
                        BoxShadow(
                          color: _goldDark.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: _goldDark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF000000),
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
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9590),
                        ),
                      ),
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  if (controller.text.isNotEmpty && onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: _goldDark,
                      ),
                    )
                  else
                    const Icon(
                      Icons.mic_none_rounded,
                      color: _goldDark,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterTap,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 22,
                      color: filterActiveCount > 0
                          ? _goldDark
                          : _goldDark.withOpacity(0.6),
                    ),
                  ),
                  if (filterActiveCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _goldDark,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$filterActiveCount',
                          style: const TextStyle(
                            fontSize: 9,
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
