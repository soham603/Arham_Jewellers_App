import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/utils/image_zoom_dialog.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatefulWidget {
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

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  static const _cardBorderColor = Color(0xFFE7E2DB);

  @override
  Widget build(BuildContext context) {
    final primaryAction = widget.onAddToCart ?? widget.onTap;
    final product = widget.product;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width * 0.45;

        final radius = (width * 0.075).clamp(10.0, 18.0);
        final hPad = (width * 0.055).clamp(7.0, 11.0);
        final vPad = (width * 0.03).clamp(4.0, 8.0);

        final bodySize = (width * 0.05).clamp(8.0, 10.0);
        final metaSize = (width * 0.05).clamp(8.0, 10.0);
        final buttonTextSize = (width * 0.06).clamp(10.0, 12.0);
        final buttonHeight = (width * 0.145).clamp(28.0, 34.0);
        final iconSize = (width * 0.18).clamp(22.0, 32.0);

        final gap2 = (width * 0.01).clamp(1.5, 3.0);
        final gap3 = (width * 0.015).clamp(2.0, 4.0);

        final displayName =
            _cleanText(product.name) ?? 'Untitled Product';
        final imageUrl = _cleanText(product.imageUrl);
        final categoryName = _cleanText(product.category?.name);
        final tagNo = _cleanText(product.tagNo);
        final fineWeight = _formatValue(product.fineWeight);
        final touchData = _parseTouch(product.touch);

        final showTagNo = !widget.compact && tagNo != null;
        final showWeight = fineWeight != null || touchData != null;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0,
                _isPressed ? 1.0 : (_isHovered ? -2.0 : 0),
                0,
              ),
              child: Tooltip(
                message: displayName,
                preferBelow: true,
                child: Semantics(
                  container: true,
                  label: '$displayName product card',
                  hint: widget.onTap != null
                      ? 'Tap to open product details'
                      : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: _isHovered
                            ? AppColors.primaryGold.withOpacity(0.3)
                            : _cardBorderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? AppColors.primaryGold.withOpacity(0.12)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: _isHovered ? 16 : 10,
                          offset: Offset(0, _isHovered ? 6 : 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(radius),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(radius),
                        mouseCursor: widget.onTap != null
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: width * 1.5,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: _ProductImage(
                                imageUrl: imageUrl,
                                productName: displayName,
                                iconSize: iconSize,
                                isNew: _isRecent(product),
                                isHovered: _isHovered,
                              ),
                            ),
                          ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: hPad,
                                vertical: vPad,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (categoryName != null)
                                    _CategoryChip(
                                      label: categoryName,
                                      maxWidth: width * 0.7,
                                      fontSize: bodySize,
                                      hPad: gap3,
                                      vPad: 1,
                                    ),
                                  if (showWeight) ...[
                                    SizedBox(height: gap3),
                                    _WeightInfo(
                                      fineWeight: fineWeight,
                                      touchData: touchData,
                                      fontSize: metaSize,
                                    ),
                                  ],

                                ],
                              ),
                            ),
                            if (!widget.compact)
                              const Spacer(),
                            if (!widget.compact)
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                    hPad, 0, hPad, vPad),
                                child: _ViewButton(
                                  onPressed: primaryAction,
                                  height: buttonHeight,
                                  fontSize: buttonTextSize,
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
          ),
        );
      },
    );
  }

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
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static _TouchData? _parseTouch(String? touch) {
    if (touch == null || touch.isEmpty) return null;
    final match = RegExp(r'([\d.]+)\s*\((\d+)\s*K\)').firstMatch(touch);
    if (match != null) {
      return _TouchData(
        karat: match.group(2),
        touchValue: match.group(1),
      );
    }
    return _TouchData(karat: null, touchValue: touch);
  }

  static bool _isRecent(ProductModel product) {
    if (product.createdAt == null) return false;
    return DateTime.now().difference(product.createdAt!).inDays < 7;
  }
}

class _TouchData {
  final String? karat;
  final String? touchValue;
  const _TouchData({this.karat, this.touchValue});
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.productName,
    required this.iconSize,
    required this.isNew,
    required this.isHovered,
  });

  final String? imageUrl;
  final String productName;
  final double iconSize;
  final bool isNew;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColoredBox(
          color: const Color(0xFFF8F5F0),
          child: AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
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
        ),
        if (isNew)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        if (imageUrl != null)
          Positioned(
            bottom: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => showImageZoomDialog(context, imageUrl!),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_full, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WeightInfo extends StatelessWidget {
  const _WeightInfo({
    required this.fineWeight,
    required this.touchData,
    required this.fontSize,
  });

  final String? fineWeight;
  final _TouchData? touchData;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      color: AppColors.textDark.withOpacity(0.7),
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
    final dimSep = style.copyWith(
      color: AppColors.textMuted.withOpacity(0.4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fineWeight != null)
          Text('Wt: ${fineWeight}g', style: style, maxLines: 1),
        if (touchData != null) ...[
          if (fineWeight != null) const SizedBox(height: 2),
          _PurityRow(data: touchData!, style: style, dimSep: dimSep),
        ],
      ],
    );
  }
}

class _PurityRow extends StatelessWidget {
  const _PurityRow({
    required this.data,
    required this.style,
    required this.dimSep,
  });

  final _TouchData data;
  final TextStyle style;
  final TextStyle dimSep;

  @override
  Widget build(BuildContext context) {
    final hasKarat = data.karat != null;
    final hasTouch = data.touchValue != null;

    final spans = <TextSpan>[];

    if (hasKarat) {
      spans.add(TextSpan(text: '${data.karat}K Gold', style: style));
    }

    if (hasKarat && hasTouch) {
      spans.add(TextSpan(text: '  •  ', style: dimSep));
    }

    if (hasTouch) {
      spans.add(TextSpan(text: '${data.touchValue} Touch', style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'View Product',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
