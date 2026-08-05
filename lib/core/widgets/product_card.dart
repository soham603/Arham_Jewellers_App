import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/utils/formatters.dart';
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
    this.isSelectMode = false,
    this.showWishlistRemoveAlert = false,
  });

  final ProductModel product;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectMode;
  final bool showWishlistRemoveAlert;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  static const _cardBorderColor = AppColors.cardBorder;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width * 0.45;

        final screenW = MediaQuery.sizeOf(context).width;
        final sf = (screenW / 414).clamp(1.0, 2.5);

        final radius = (width * 0.075).clamp(10.0 * sf, 22.0 * sf);
        final hPad = (width * 0.055).clamp(7.0 * sf, 14.0 * sf);
        final vPad = (width * 0.03).clamp(4.0 * sf, 10.0 * sf);

        final bodySize = (width * 0.05).clamp(8.0 * sf, 13.0 * sf);
        final metaSize = (width * 0.05).clamp(8.0 * sf, 13.0 * sf);
        final buttonTextSize = (width * 0.06).clamp(10.0 * sf, 15.0 * sf);
        final buttonHeight = (width * 0.145).clamp(28.0 * sf, 44.0 * sf);
        final iconSize = (width * 0.18).clamp(22.0 * sf, 40.0 * sf);

        final gap2 = (width * 0.01).clamp(1.5 * sf, 3.0 * sf);
        final gap3 = (width * 0.015).clamp(2.0 * sf, 4.0 * sf);

        final displayName =
            _cleanText(product.name) ?? 'Untitled Product';
        final imageUrl = _cleanText(product.displayImageUrl);
        final categoryName = _cleanText(product.category?.name);
        final tagNo = _cleanText(product.tagNo);
        final fineWeight = _formatValue(product.karigarNetWt);
        final touchData = _parseTouch(product.touch);
        final size = _cleanText(product.size);

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
                                      ? AppColors.primaryGold.withValues(alpha: 0.3)
                                      : _cardBorderColor,
                              width: widget.isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isSelected
                                    ? AppColors.primaryGold.withValues(alpha: 0.2)
                                    : _isHovered
                                        ? AppColors.primaryGold.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.06),
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
                                        cardRadius: radius,
                                        isAdmin: Get.find<AuthController>().isAdmin,
                                      ),
                                    ),
                                  ),
                                  if (categoryName != null)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(vertical: vPad),
                                        decoration: const BoxDecoration(
                                          color: AppColors.categoryChipBg,
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
                                  if (tagNo != null)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        hPad,
                                        categoryName != null ? gap3 : vPad,
                                        hPad,
                                        gap3,
                                      ),
                                      child: Text(
                                        tagNo,
                                        style: TextStyle(
                                          fontSize: metaSize,
                                          color: AppColors.textDark.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (showWeight)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        hPad,
                                        tagNo != null ? gap3 : (categoryName != null ? gap3 : vPad),
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
                            top: 6 * sf,
                            right: 6 * sf,
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
                                  padding: EdgeInsets.all(4 * sf),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4 * sf,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    color: isWishlisted ? Colors.redAccent : AppColors.primaryGold,
                                    size: 16 * sf,
                                  ),
                                ),
                              );
                            }),
                          ),
                        if (widget.isSelected)
                          Positioned(
                            top: 6 * sf,
                            right: Get.find<AuthController>().isAdmin ? 6 * sf : 36 * sf,
                            child: Container(
                              padding: EdgeInsets.all(4 * sf),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4 * sf,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14 * sf,
                              ),
                            ),
                          )
                        else if (widget.isSelectMode)
                          Positioned(
                            top: 6 * sf,
                            right: Get.find<AuthController>().isAdmin ? 6 * sf : 36 * sf,
                            child: Container(
                              padding: EdgeInsets.all(2 * sf),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryGold,
                                  width: 2 * sf,
                                ),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.transparent,
                                size: 14 * sf,
                              ),
                            ),
                          ),
                        if (_showAdminStatusBadge())
                          Positioned(
                            top: 6 * sf,
                            left: 6 * sf,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7 * sf,
                                vertical: 3 * sf,
                              ),
                              decoration: BoxDecoration(
                                color: product.isActive
                                    ? Colors.green.withValues(alpha: 0.9)
                                    : Colors.orange.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10 * sf),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4 * sf,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6 * sf,
                                    height: 6 * sf,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4 * sf),
                                  Text(
                                    product.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10 * sf,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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

  static String? _formatValue(Object? value) => formatWeight(value);

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
    } catch (e, st) {
      return false;
    }
  }

  static bool _showAdminStatusBadge() {
    try {
      return Get.find<AuthController>().isAdmin;
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
    required this.cardRadius,
    this.isAdmin = false,
  });

  final String? imageUrl;
  final String productName;
  final double iconSize;
  final bool isNew;
  final bool isHovered;
  final double width;
  final double cardRadius;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final sf = (screenW / 414).clamp(1.0, 2.5);
    final badgeSize = (width * 0.03).clamp(6.0, 10.0);
    final badgeFontSize = (width * 0.04).clamp(8.0, 11.0);
    final zoomIconSize = (width * 0.07).clamp(16.0, 22.0);
    final zoomPad = (width * 0.025).clamp(6.0, 10.0);

    final imageProvider = imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null;

    final imgPad = (width * 0.01).clamp(1.0, 3.0);
    final imgRadius = cardRadius;
    final imgBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(imgRadius),
      topRight: Radius.circular(imgRadius),
    );

    return Stack(
      children: [
        if (imageProvider != null)
          Padding(
            padding: EdgeInsets.all(imgPad),
            child: ClipRRect(
              borderRadius: imgBorderRadius,
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Transform.scale(
                    scale: 1.1,
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) return child;
                        return const DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.cardBgLight),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (imageProvider != null)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(imgPad),
              child: ClipRRect(
                borderRadius: imgBorderRadius,
                child: AnimatedScale(
                  scale: isHovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: Semantics(
                    image: true,
                    label: '$productName image',
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) return child;
                        return Shimmer.fromColors(
                          baseColor: AppColors.warmShimmerBase,
                          highlightColor: AppColors.shimmerHighlight,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const RatneshFallback.m(),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const RatneshFallback.m(),
        if (isNew)
          Positioned(
            top: isAdmin ? 26 * sf : badgeSize,
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
      color: AppColors.textDark.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
    final dimSep = style.copyWith(
      color: AppColors.textMuted.withValues(alpha: 0.4),
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

    final formatted = formatPrice(total);

    return Row(
      children: [
        Text(
          formatted,
          style: TextStyle(
            fontSize: fontSize + 4,
            color: AppColors.primaryGold,
            fontWeight: FontWeight.w700,
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
          disabledBackgroundColor: AppColors.primaryGold.withValues(alpha: 0.45),
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
      child: Obx(() {
        final inCart = CartController.instance.isInCart(product.id);

        return ElevatedButton(
          onPressed: () {
            if (inCart) {
              CartController.instance.removeFromCart(product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} removed from cart'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              CartController.instance.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: inCart ? Colors.white : AppColors.primaryGold,
            foregroundColor: inCart ? AppColors.primaryGold : Colors.white,
            padding: EdgeInsets.zero,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            side: inCart
                ? BorderSide(
                    color: AppColors.primaryGold.withValues(alpha: 0.6),
                    width: 1.2,
                  )
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(
            inCart ? Icons.remove_shopping_cart_outlined : Icons.shopping_cart_outlined,
            size: height * 0.45,
          ),
        );
      }),
    );
  }
}
