import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/utils/formatters.dart';
import 'package:ratnesh_gold_app/core/utils/string_utils.dart';
import 'package:ratnesh_gold_app/core/utils/image_zoom_dialog.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/navigation_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/wishlist_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

import 'customise_order_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/product_edit_page.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    super.key,
    required this.product,
    this.products,
    this.initialIndex = 0,
    this.controller,
    this.listType,
  });

  final ProductModel product;
  final List<ProductModel>? products;
  final int initialIndex;
  final SearchProductController? controller;
  final String? listType;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final CartController cartController;
  late int _currentIndex;
  PageController? _pageController;
  final RxList<ProductModel> _liveProducts = <ProductModel>[].obs;
  Worker? _productsWorker;

  bool get _hasController => widget.controller != null;
  bool get _canSwipe => _effectiveProducts.length > 1;

  List<ProductModel> get _effectiveProducts {
    if (_hasController) {
      return _liveProducts.isNotEmpty ? _liveProducts : (widget.products ?? []);
    }
    return widget.products ?? [];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    if (_hasController) {
      _liveProducts.assignAll(widget.products ?? _getControllerList());
      final idx = _liveProducts.indexWhere((p) => p.id == widget.product.id);
      if (idx != -1) {
        _currentIndex = idx;
      }
      _productsWorker = ever(_getControllerObservable(), (_) {
        final newList = _getControllerList();
        final oldLen = _liveProducts.length;
        if (newList.isNotEmpty) {
          _liveProducts.assignAll(newList);
        }
        if (mounted && oldLen != _liveProducts.length) {
          setState(() {});
        }
      });
    } else if (widget.products != null) {
      _liveProducts.assignAll(widget.products!);
    }

    if (_canSwipe) {
      _pageController = PageController(initialPage: _currentIndex);
    }

    if (Get.isRegistered<CartController>()) {
      cartController = Get.find<CartController>();
    } else {
      cartController = Get.put(CartController());
    }

    if (widget.product.isOld22kReadyStock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.back();
          Get.snackbar('Not Available', 'This item is no longer available');
        }
      });
    }
  }

  RxList<ProductModel> _getControllerObservable() {
    final c = widget.controller!;
    switch (widget.listType) {
      case 'filtered':
        return c.filteredProducts as RxList<ProductModel>;
      case 'category':
        return c.categoryProducts as RxList<ProductModel>;
      case 'karat':
      default:
        return c.karatProducts as RxList<ProductModel>;
    }
  }

  List<ProductModel> _getControllerList() {
    final c = widget.controller!;
    switch (widget.listType) {
      case 'filtered':
        return c.filteredProducts;
      case 'category':
        return c.categoryProducts;
      case 'karat':
      default:
        return c.karatProducts;
    }
  }

  void _loadMoreIfNeeded() {
    if (!_hasController) return;
    final c = widget.controller!;
    switch (widget.listType) {
      case 'filtered':
        c.loadMoreFilteredProducts();
        break;
      case 'category':
        break;
      case 'karat':
      default:
        c.loadMoreKaratProducts();
        break;
    }
  }

  @override
  void dispose() {
    _productsWorker?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  ProductModel get _currentProduct {
    final products = _effectiveProducts;
    if (products.isNotEmpty && _currentIndex < products.length) {
      return products[_currentIndex];
    }
    return widget.product;
  }

  String _getConvertedPurity(
    Map<String, dynamic> rawData,
    String? karat, {
    String? tagNo,
    String? name,
  }) {
    final touchRaw =
        rawData['SalesTouch']?.toString().trim() ??
        rawData['Touch']?.toString().trim();
    if (touchRaw != null && touchRaw.isNotEmpty) {
      final resolved = _resolvePurityValue(touchRaw);
      if (resolved != null) return resolved;
    }

    if (tagNo != null && tagNo.length >= 2) {
      final resolved = _resolvePurityValue(tagNo.substring(0, 2));
      if (resolved != null) return resolved;
    }

    if (karat != null && karat.isNotEmpty) {
      final resolved = _resolveKaratValue(karat);
      if (resolved != null) return resolved;
      return '$karat K Gold';
    }

    if (name != null && name.isNotEmpty) {
      final resolved = _resolvePurityValue(name);
      if (resolved != null) return resolved;
      final resolved2 = _resolveKaratValue(name);
      if (resolved2 != null) return resolved2;
    }

    return '\u2014';
  }

  String? _resolvePurityValue(String raw) {
    final match = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(raw.trim());
    final numStr = match?.group(1);
    if (numStr == null) return null;
    var value = double.tryParse(numStr);
    if (value == null) return null;

    if (value < 1) {
      value *= 1000; 
    } else if (value < 100) {
      value *= 10; 
    }
    value = value.roundToDouble();

    if (value >= 995 && value <= 1005) return "$numStr (24 K)";
    if (value >= 915 && value <= 925) return "$numStr (22 K)";
    if (value >= 835 && value <= 845) return "$numStr (20 K)";
    if (value >= 755 && value <= 765) return "$numStr (18 K)";
    if (value >= 595 && value <= 605) return "$numStr (14 K)";
    if (value >= 375 && value <= 385) return "$numStr (9 K)";

    return null;
  }

  String? _resolveKaratValue(String raw) {
    final match = RegExp(
      r'(\d+)\s*K',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    final numStr = match?.group(1);
    if (numStr == null) return null;
    final value = int.tryParse(numStr);
    if (value == null) return null;

    switch (value) {
      case 9:
        return '0.380 (9 K)';
      case 14:
        return '0.600 (14 K)';
      case 18:
        return '0.760 (18 K)';
      case 20:
        return '0.840 (20 K)';
      case 22:
        return '0.920 (22 K)';
      case 24:
        return '1.000 (24 K)';
    }
    return null;
  }

  double? _calculatePriceForProduct(ProductModel product) {
    final goldRate = Get.find<GoldRateController>().currentRate;
    if (goldRate == null || product.karigarNetWt == null) return null;
    return GoldRateController.calculatePrice(
      fineWeight:
          product.karigarNetWt ??
          0,
      ratePer10Gram: goldRate.rate,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,

      
      bottomNavigationBar: Get.find<AuthController>().isAdmin
          ? const SizedBox.shrink()
          : Obx(() {
              final quantity = cartController.getProductQuantity(
                _currentProduct.id,
              );
              final isInCart = quantity > 0;

              return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    context.getResponsiveSize(4),
                    context.heightPercent(1.5),
                    context.getResponsiveSize(4),
                    context.heightPercent(1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: context.heightPercent(6.2),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              shadowColor: AppColors.primaryGold.withValues(
                                alpha: 0.2,
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.primaryGold.withValues(
                                    alpha: isInCart ? 0.6 : 0.4,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            onPressed: isInCart
                                ? () {
                                    cartController.removeFromCart(
                                      _currentProduct.id,
                                    );
                                  }
                                : () {
                                    cartController.addToCart(_currentProduct);
                                  },
                            child: Text(
                              isInCart ? 'Remove from Cart' : 'Add to Cart',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: context.getResponsiveSize(3)),
                      Expanded(
                        child: SizedBox(
                          height: context.heightPercent(6.2),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 6,
                              shadowColor: AppColors.primaryGold.withValues(
                                alpha: 0.5,
                              ),
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                              Get.find<NavigationController>().switchTab(NavigationController.cartIndex);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart,
                                      size: context.getResponsiveSize(4.5),
                                      color: Colors.white,
                                    ),
                                    if (cartController.totalItems > 0)
                                      Positioned(
                                        right: -context.getResponsiveSize(
                                          2.5,
                                          minSize: 0,
                                        ),
                                        top: -context.getResponsiveSize(
                                          2.5,
                                          minSize: 0,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            context.getResponsiveSize(
                                              0.6,
                                              minSize: 0,
                                            ),
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: context
                                                .getResponsiveSize(
                                              3.8,
                                              minSize: 0,
                                            ),
                                            minHeight: context
                                                .getResponsiveSize(
                                              3.8,
                                              minSize: 0,
                                            ),
                                          ),
                                          child: Text(
                                            '${cartController.totalItems}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: context
                                                  .getResponsiveSize(
                                                2.5,
                                                minSize: 0,
                                              ),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(width: context.getResponsiveSize(2)),
                                Text(
                                  'View Cart',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.5),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              );
            }),

      
      
      body: _canSwipe
          ? (() {
              final products = _effectiveProducts;
              if (_currentIndex >= products.length) {
                _currentIndex = products.length - 1;
              }
              return PageView.builder(
                controller: _pageController,
                itemCount: products.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (products.length - index <= 3) {
                    _loadMoreIfNeeded();
                  }
                },
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductContent(product);
                },
              );
            })()
          : _buildProductContent(widget.product),
    );
  }

  Widget _buildProductContent(ProductModel product) {
    final rawData = product.rawData ?? {};
    final netWeight = rawData["KarigarNetWt"]?.toString();
    final grossWeight = rawData["GrossWt"]?.toString();
    final displayGrossWeight = grossWeight ?? netWeight;
    final purity = _getConvertedPurity(
      rawData,
      product.karat,
      tagNo: product.tagNo,
      name: product.name,
    );
    final pieces = rawData["Pieces"]?.toString() ?? "1";
    final collectionName = product.category?.name ?? "—";
    final size = product.size?.toString();
    final price = _calculatePriceForProduct(product);

    final isStockField = product.rawData?['IsStock'];
    final bool inStock = isStockField != null
        ? (isStockField == 1 || isStockField == true || isStockField == '1')
        : product.isActive;
    final String stockText = inStock ? "READY STOCK" : "OUT OF STOCK";
    final Color stockColor = inStock
        ? AppColors.primaryGold
        : Colors.red.shade600;

    return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(
              height: context.heightPercent(65),
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFE6E1D9),
                      child: product.displayImageUrl != null &&
                              product.displayImageUrl!.trim().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.displayImageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: const Color(0xFFE7E2DB),
                                highlightColor: const Color(0xFFF5F1EB),
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: context.getResponsiveSize(12),
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                '[ No Image ]',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(5),
                                  color: const Color(0xFF8C7E68),
                                ),
                              ),
                            ),
                    ),
                  ),

                  Positioned(
                    top: context.heightPercent(2),
                    left: context.getResponsiveSize(4),
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: context.getResponsiveSize(5),
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),

                  if (!Get.find<AuthController>().isAdmin)
                    Positioned(
                      top: context.heightPercent(2),
                      right: context.getResponsiveSize(4),
                      child: Obx(() {
                        final isWishlisted = WishlistController.instance.isWishlisted(product.id);
                        return GestureDetector(
                          onTap: () {
                            if (isWishlisted) {
                              WishlistController.instance.removeFromWishlist(product.id);
                              ScaffoldMessenger.of(context).showSnackBar(
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
                              WishlistController.instance.addToWishlist(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added to wishlist'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isWishlisted ? Icons.favorite : Icons.favorite_border,
                              color: isWishlisted ? Colors.redAccent : AppColors.primaryGold,
                              size: context.getResponsiveSize(5),
                            ),
                          ),
                        );
                      }),
                    ),

                  if (Get.find<AuthController>().isAdmin)
                    Positioned(
                      top: context.heightPercent(2),
                      right: context.getResponsiveSize(4),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(3),
                          vertical: context.heightPercent(0.6),
                        ),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green.withValues(alpha: 0.92)
                              : Colors.orange.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: context.getResponsiveSize(1.8),
                              height: context.getResponsiveSize(1.8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: context.getResponsiveSize(1.5)),
                            Text(
                              product.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.getResponsiveSize(3),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (product.imageUrl != null)
                    Positioned(
                      bottom: context.heightPercent(4),
                      right: context.getResponsiveSize(4),
                      child: GestureDetector(
                        onTap: () => showImageZoomDialog(
                          context,
                          product.imageUrl!,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.open_in_full,
                            size: context.getResponsiveSize(5),
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(5),
                context.heightPercent(3),
                context.getResponsiveSize(5),
                context.heightPercent(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cleanCategoryName(product.name)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(5.5),
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2C3E50),
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: context.heightPercent(0.3)),
                            Text(
                              "Tag: ${product.tagNo ?? rawData['Barcode'] ?? '-'}",
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.2),
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: context.heightPercent(0.6)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.getResponsiveSize(3),
                                vertical: context.heightPercent(0.4),
                              ),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: stockColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                stockText,
                                style: TextStyle(
                                  color: stockColor,
                                  fontSize: context.getResponsiveSize(2.5),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (price != null &&
                          (Get.find<AuthController>().user?.isRetailer == true ||
                              Get.find<AuthController>().isAdmin))
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getResponsiveSize(4),
                            vertical: context.heightPercent(0.8),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGold.withValues(alpha: 0.1),
                                AppColors.primaryGold.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "PRICE",
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.2),
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                formatPrice(price),
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(5),
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: context.heightPercent(1.5)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Specification",
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C3E50),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (Get.find<AuthController>().isAdmin)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductEditPage(product: product),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.edit,
                            size: context.getResponsiveSize(4),
                            color: Colors.white,
                          ),
                          label: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(2.8),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            elevation: 3,
                            shadowColor: AppColors.primaryGold.withValues(
                              alpha: 0.4,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getResponsiveSize(4),
                              vertical: context.heightPercent(0.8),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.to(
                              () => CustomiseOrderPage(product: product),
                            );
                          },
                          icon: Icon(
                            Icons.tune,
                            size: context.getResponsiveSize(4),
                            color: Colors.white,
                          ),
                          label: Text(
                            "Customize",
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(2.8),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            elevation: 3,
                            shadowColor: AppColors.primaryGold.withValues(
                              alpha: 0.4,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getResponsiveSize(4),
                              vertical: context.heightPercent(0.8),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: context.heightPercent(1)),

                  if (grossWeight != null || netWeight != null) ...[
                    Row(
                      children: [
                        if (netWeight != null)
                          Expanded(
                            child: _buildSpecBox(
                              context,
                              Icons.scale_outlined,
                              "NET WT.",
                              "$netWeight g",
                            ),
                          ),
                        if (netWeight != null && displayGrossWeight != null)
                          SizedBox(width: context.getResponsiveSize(3)),
                        if (displayGrossWeight != null)
                          Expanded(
                            child: _buildSpecBox(
                              context,
                              Icons.work_outline,
                              "GROSS WT.",
                              "$displayGrossWeight g",
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.heightPercent(1)),
                    Row(
                      children: [
                        if (netWeight != null)
                          Expanded(
                            child: _buildSpecBox(
                              context,
                              Icons.diamond_outlined,
                              "PURITY",
                              purity,
                            ),
                          ),
                        if (netWeight != null && displayGrossWeight != null)
                          SizedBox(width: context.getResponsiveSize(3)),
                        if (displayGrossWeight != null)
                          Expanded(
                            child: _buildSpecBox(
                              context,
                              Icons.grid_view_outlined,
                              "PIECES",
                              pieces,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (netWeight == null && grossWeight == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpecBox(
                            context,
                            Icons.diamond_outlined,
                            "PURITY",
                            purity,
                          ),
                        ),
                        SizedBox(width: context.getResponsiveSize(3)),
                        Expanded(
                          child: _buildSpecBox(
                            context,
                            Icons.grid_view_outlined,
                            "PIECES",
                            pieces,
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: context.heightPercent(1)),

                  if (size != null && size.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: _buildSpecBox(
                        context,
                        Icons.straighten,
                        "SIZE",
                        size,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(1)),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: _buildSpecBox(
                      context,
                      Icons.category_outlined,
                      "COLLECTION NAME",
                      collectionName,
                    ),
                  ),

                  SizedBox(height: context.heightPercent(1.5)),

                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(4),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),

                  SizedBox(height: context.heightPercent(0.5)),

                  Text(
                    "Elegant ${cleanCategoryName(product.name)} with fine craftsmanship, $purity purity, and a timeless design—perfect for pairing with traditional Indian ensembles or adding everyday elegance.",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.2),
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: context.heightPercent(1.5)),

                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: context.heightPercent(1.2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTrustBadge(
                            context,
                            Icons.local_shipping_outlined,
                            "Pan-India\nShipping",
                          ),
                        ),
                        Expanded(
                          child: _buildTrustBadge(
                            context,
                            Icons.verified_outlined,
                            "Certified\nQuality",
                          ),
                        ),
                        Expanded(
                          child: _buildTrustBadge(
                            context,
                            Icons.star_border,
                            "Premium\nFinish",
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.heightPercent(1)),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSpecBox(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(3),
        vertical: context.heightPercent(1),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGold.withValues(alpha: 0.8),
            size: context.getResponsiveSize(6),
          ),
          SizedBox(width: context.getResponsiveSize(2.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.2),
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.3)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.2),
                    color: const Color(0xFF2C3E50),
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.primaryGold.withValues(alpha: 0.7),
          size: context.getResponsiveSize(5),
        ),
        SizedBox(width: context.getResponsiveSize(1.5)),
        Text(
          text,
          style: TextStyle(
            fontSize: context.getResponsiveSize(2.5),
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
