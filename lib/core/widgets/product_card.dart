import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/utils/image_zoom_dialog.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/wishlist_controller.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.onTap,
    this.onAddToCart,
    this.onLongPress,
    this.isSelected = false,
    this.showWishlistRemoveAlert = false,
  });

  final ProductModel product;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showWishlistRemoveAlert;

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
    final product = widget.product;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width * 0.45;

        final radius = (width * 0.075).clamp(10.0, 22.0);
        final hPad = (width * 0.055).clamp(7.0, 14.0);
        final vPad = (width * 0.03).clamp(4.0, 10.0);

        final bodySize = (width * 0.05).clamp(8.0, 12.0);
        final metaSize = (width * 0.05).clamp(8.0, 12.0);
        final buttonTextSize = (width * 0.06).clamp(10.0, 14.0);
        final buttonHeight = (width * 0.145).clamp(28.0, 40.0);
        final iconSize = (width * 0.18).clamp(22.0, 38.0);

        final gap2 = (width * 0.01).clamp(1.5, 3.0);
        final gap3 = (width * 0.015).clamp(2.0, 4.0);

        final displayName =
            _cleanText(product.name) ?? 'Untitled Product';
        final imageUrl = _cleanText(product.displayImageUrl);
        final categoryName = _cleanText(product.category?.name);
        final tagNo = _cleanText(product.tagNo);
        final fineWeight = _formatValue(product.karigarNetWt);
        final touchData = _parseTouch(product.touch);
        final size = _cleanText(product.size);

        final showTagNo = !widget.compact && tagNo != null;
        final showWeight = fineWeight != null || touchData != null || size != null;

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
                  child: Stack(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(
                              color: widget.isSelected
                                  ? AppColors.primaryGold
                                  : _isHovered
                                      ? AppColors.primaryGold.withOpacity(0.3)
                                      : _cardBorderColor,
                              width: widget.isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isSelected
                                    ? AppColors.primaryGold.withOpacity(0.2)
                                    : _isHovered
                                        ? AppColors.primaryGold.withOpacity(0.12)
                                        : Colors.black.withOpacity(0.06),
                                blurRadius: widget.isSelected ? 12 : (_isHovered ? 16 : 10),
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
                              onLongPress: widget.onLongPress,
                              borderRadius: BorderRadius.circular(radius),
                              mouseCursor: widget.onTap != null
                                  ? SystemMouseCursors.click
                                  : MouseCursor.defer,
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 3 / 4,
                                      child: _ProductImage(
                                        imageUrl: imageUrl,
                                        productName: displayName,
                                        iconSize: iconSize,
                                        isNew: _isRecent(product),
                                        isHovered: _isHovered,
                                        width: width,
                                      ),
                                    ),
                                  ),
                                  if (categoryName != null)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(vertical: vPad),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFF6DD),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(100),
                                            bottomRight: Radius.circular(100),
                                          ),
                                        ),
                                        padding: EdgeInsets.only(
                                          left: hPad,
                                          right: vPad,
                                          top: 1,
                                          bottom: 1,
                                        ),
                                        constraints: BoxConstraints(maxWidth: width * 0.7),
                                        child: Text(
                                          categoryName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: bodySize,
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (showWeight)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        hPad,
                                        categoryName != null ? gap3 : vPad,
                                        hPad,
                                        vPad,
                                      ),
                                      child: _WeightInfo(
                                        fineWeight: fineWeight,
                                        touchData: touchData,
                                        size: size,
                                        fontSize: metaSize,
                                      ),
                                    ),
                                  if (!widget.compact && _showRetailerPrice(product))
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(hPad, gap3, hPad, vPad),
                                      child: _RetailerPrice(
                                        product: product,
                                        fontSize: metaSize,
                                      ),
                                    ),
                                  if (!widget.compact)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(hPad, gap3, hPad, hPad),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _ViewButton(
                                              onPressed: widget.onTap,
                                              height: buttonHeight,
                                              fontSize: buttonTextSize,
                                            ),
                                          ),
                                          SizedBox(width: gap2),
                                          _CartButton(
                                            product: widget.product,
                                            height: buttonHeight,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!Get.find<AuthController>().isAdmin)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Obx(() {
                              final isWishlisted = WishlistController.instance.isWishlisted(product.id);
                              return GestureDetector(
                                onTap: () {
                                  if (isWishlisted) {
                                    if (widget.showWishlistRemoveAlert) {
                                      final messenger = ScaffoldMessenger.of(context);
                                      WishlistController.instance.removeFromWishlist(product.id);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('${product.name} removed from wishlist'),
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            textColor: AppColors.primaryGold,
                                            onPressed: () {
                                              WishlistController.instance.addToWishlist(product);
                                            },
                                          ),
                                        ),
                                      );
                                    } else {
                                      WishlistController.instance.removeFromWishlist(product.id);
                                    }
                                  } else {
                                    WishlistController.instance.addToWishlist(product);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    color: isWishlisted ? Colors.redAccent : AppColors.primaryGold,
                                    size: 16,
                                  ),
                                ),
                              );
                            }),
                          ),
                        if (widget.isSelected)
                          Positioned(
                            top: 6,
                            right: 36,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
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

  static bool _showRetailerPrice(ProductModel product) {
    if (product.karigarNetWt == null) return false;
    try {
      final auth = Get.find<AuthController>();
      final isRetailer = auth.user?.isRetailer == true;
      final isAdmin = auth.isAdmin;
      if (!isRetailer && !isAdmin) return false;
      final goldRate = Get.find<GoldRateController>().currentRate;
      return goldRate != null;
    } catch (_) {
      return false;
    }
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
    required this.width,
  });

  final String? imageUrl;
  final String productName;
  final double iconSize;
  final bool isNew;
  final bool isHovered;
  final double width;

  @override
  Widget build(BuildContext context) {
    final badgeSize = (width * 0.03).clamp(6.0, 10.0);
    final badgeFontSize = (width * 0.04).clamp(8.0, 11.0);
    final zoomIconSize = (width * 0.07).clamp(16.0, 22.0);
    final zoomPad = (width * 0.025).clamp(6.0, 10.0);

    return Stack(
      children: [
        if (imageUrl != null)
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: ColoredBox(
                color: const Color(0xFFF8F5F0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFF8F5F0)),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (imageUrl != null)
          Positioned.fill(
            child: AnimatedScale(
              scale: isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: Semantics(
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
                  errorWidget: (context, url, error) => const RatneshFallback.m(),
                ),
              ),
            ),
          )
        else
          const RatneshFallback.m(),
        if (isNew)
          Positioned(
            top: badgeSize,
            left: badgeSize,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: badgeSize * 0.8, vertical: badgeSize * 0.3),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(badgeSize * 0.5),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: badgeFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        if (imageUrl != null)
          Positioned(
            bottom: zoomPad,
            right: zoomPad,
            child: GestureDetector(
              onTap: () => showImageZoomDialog(context, imageUrl!),
              child: Container(
                padding: EdgeInsets.all(zoomPad * 0.6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.open_in_full, color: Colors.white, size: zoomIconSize),
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
    this.size,
  });

  final String? fineWeight;
  final _TouchData? touchData;
  final double fontSize;
  final String? size;

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
          Text('Net Wt: ${fineWeight}g', style: style, maxLines: 1),
        if (touchData != null) ...[
          if (fineWeight != null) const SizedBox(height: 2),
          _PurityRow(data: touchData!, style: style, dimSep: dimSep),
        ],
        if (size != null) ...[
          if (fineWeight != null || touchData != null) const SizedBox(height: 2),
          Text(size!, style: style, maxLines: 1),
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
      spans.add(TextSpan(text: '${data.karat}K', style: style));
    }

    if (hasKarat && hasTouch) {
      spans.add(TextSpan(text: '  •  ', style: dimSep));
    }

    if (hasTouch) {
      spans.add(TextSpan(text: '${data.touchValue}', style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _RetailerPrice extends StatelessWidget {
  const _RetailerPrice({
    required this.product,
    required this.fontSize,
  });

  final ProductModel product;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final goldRate = Get.find<GoldRateController>().currentRate;
    if (goldRate == null || product.karigarNetWt == null) {
      return const SizedBox.shrink();
    }

    final total = GoldRateController.calculatePrice(
      fineWeight: product.karigarNetWt ?? 0,
      ratePer10Gram: goldRate.rate,
    )!;

    final formatted = _formatPrice(total);

    return Row(
      children: [
        Text(
          '₹$formatted',
          style: TextStyle(
            fontSize: fontSize + 4,
            color: AppColors.primaryGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static String _formatPrice(double price) {
    final rounded = price.round();
    final parts = rounded.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return buffer.toString();
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

class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.product,
    required this.height,
  });

  final ProductModel product;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isAdmin = Get.find<AuthController>().isAdmin;
    if (isAdmin) return const SizedBox.shrink();

    return SizedBox(
      width: height,
      height: height,
      child: ElevatedButton(
        onPressed: () {
          CartController.instance.addToCart(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Icon(Icons.shopping_cart_outlined, size: 18),
      ),
    );
  }
}
