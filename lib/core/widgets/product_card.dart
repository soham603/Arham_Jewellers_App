import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.onTap,
    this.onAddToCart,
  });

  final ProductModel product;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  static const _cardBorderColor = Color(0xFFE7E2DB);
  static const _imageBackgroundColor = Color(0xFFF8F5F0);
  static const _categoryChipColor = Color(0xFFFFF6DD);

  @override
  Widget build(BuildContext context) {
    final primaryAction = onAddToCart ?? onTap;

    return LayoutBuilder(
      builder: (context, constraints) {
        // ── Sizing tokens derived from card width ──────────────────────
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width * 0.45;

        final radius = (width * 0.075).clamp(10.0, 18.0);
        final imagePadding = (width * 0.05).clamp(6.0, 14.0);
        final hPad = (width * 0.065).clamp(8.0, 14.0);
        final vPad = (width * 0.045).clamp(6.0, 12.0);

        final titleSize = (width * 0.082).clamp(11.5, 15.0);
        final bodySize = (width * 0.062).clamp(9.0, 11.5);
        final chipSize = (width * 0.058).clamp(8.5, 11.0);
        final buttonTextSize = (width * 0.070).clamp(11.0, 13.5);
        final buttonHeight = (width * 0.20).clamp(34.0, 42.0);
        final iconSize = (width * 0.18).clamp(22.0, 32.0);

        // Scale gaps down proportionally — key fix for overflow
        final gap2 = (width * 0.015).clamp(2.0, 4.0);
        final gap4 = (width * 0.025).clamp(3.0, 6.0);
        final gap6 = (width * 0.032).clamp(4.0, 7.0);
        final gap8 = (width * 0.038).clamp(5.0, 8.0);

        final displayName = _cleanText(product.name) ?? 'Untitled Product';
        final imageUrl = _cleanText(product.imageUrl);
        final categoryName = _cleanText(product.category?.name);
        final tagNo = _cleanText(product.tagNo);
        final fineWeight = _formatValue(product.fineWeight);
        final touch = _formatValue(product.touch);

        // In compact mode, hide tag number to prevent overflow
        final showTagNo = !compact && tagNo != null;
        final showWeight = fineWeight != null || touch != null;

        return Tooltip(
          message: displayName,
          preferBelow: true,
          child: Semantics(
            container: true,
            label: '$displayName product card',
            hint: onTap != null ? 'Tap to open product details' : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: _cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  mouseCursor: onTap != null
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.primaryGold.withOpacity(0.08);
                      }
                      if (states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)) {
                        return AppColors.primaryGold.withOpacity(0.04);
                      }
                      return null;
                    },
                  ),
                  child: Column(
                    children: [
                      // ── Image section ────────────────────────────────
                      Expanded(
                        flex: 6,
                        child: _ProductImage(
                          imageUrl: imageUrl,
                          productName: displayName,
                          padding: imagePadding,
                          iconSize: iconSize,
                        ),
                      ),

                      // ── Info section ─────────────────────────────────
                      Expanded(
                        flex: compact ? 4 : 5,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: vPad,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    color: AppColors.textDark,
                                  ),
                                ),

                                if (categoryName != null) ...[
                                  SizedBox(height: gap4),
                                  _CategoryChip(
                                    label: categoryName,
                                    maxWidth: width * 0.75,
                                    fontSize: chipSize,
                                    hPad: gap6,
                                    vPad: gap2,
                                  ),
                                ],

                                if (showTagNo) ...[
                                  SizedBox(height: gap4),
                                  Text(
                                    tagNo!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: bodySize,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],

                                if (showWeight) ...[
                                  SizedBox(height: gap4),
                                  _WeightRow(
                                    fineWeight: fineWeight,
                                    touch: touch,
                                    fontSize: bodySize,
                                  ),
                                ],

                                if (!compact) ...[
                                  SizedBox(height: gap8),
                                  _ViewButton(
                                    onPressed: primaryAction,
                                    height: buttonHeight,
                                    fontSize: buttonTextSize,
                                  ),
                                ],
                              ],
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
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static String? _cleanText(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null ||
        cleaned.isEmpty ||
        cleaned.toLowerCase() == 'null') {
      return null;
    }
    return cleaned;
  }

  static String? _formatValue(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }
    final parsed = num.tryParse(raw);
    if (parsed == null) return raw;
    if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
    return parsed.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.productName,
    required this.padding,
    required this.iconSize,
  });

  final String? imageUrl;
  final String productName;
  final double padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8F5F0),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: imageUrl != null
            ? Semantics(
                image: true,
                label: '$productName image',
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFFE8E3DB),
                    highlightColor: const Color(0xFFF7F3ED),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey.shade400,
                      size: iconSize,
                    ),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  Icons.image_outlined,
                  color: const Color(0xFF887A67),
                  size: iconSize,
                ),
              ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.maxWidth,
    required this.fontSize,
    required this.hPad,
    required this.vPad,
  });

  final String label;
  final double maxWidth;
  final double fontSize;
  final double hPad;
  final double vPad;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DD),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.primaryGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({
    required this.fineWeight,
    required this.touch,
    required this.fontSize,
  });

  final String? fineWeight;
  final String? touch;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      color: AppColors.textDark,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        if (fineWeight != null)
          Expanded(
            child: Text(
              'Wt $fineWeight',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        if (touch != null)
          Expanded(
            child: Text(
              'Touch: $touch',
              textAlign: fineWeight != null
                  ? TextAlign.end
                  : TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.onPressed,
    required this.height,
    required this.fontSize,
  });

  final VoidCallback? onPressed;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryGold,
          disabledBackgroundColor: AppColors.primaryGold.withOpacity(0.45),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.zero,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'View Product',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}