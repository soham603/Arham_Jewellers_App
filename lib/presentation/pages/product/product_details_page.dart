import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
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

// Import your new Customise Order Page here
import 'customise_order_page.dart';

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
  bool get _canSwipe => _liveProducts.length > 1;

  List<ProductModel> get _effectiveProducts =>
      _hasController ? _liveProducts : (widget.products ?? []);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    if (_hasController) {
      _liveProducts.assignAll(_getControllerList());
      final idx = _liveProducts.indexWhere((p) => p.id == widget.product.id);
      if (idx != -1) {
        _currentIndex = idx;
      }
      _productsWorker = ever(_getControllerObservable(), (_) {
        final newList = _getControllerList();
        final oldLen = _liveProducts.length;
        _liveProducts.assignAll(newList);
        if (mounted && oldLen != newList.length) {
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

    // Fallback: extract from product name
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

    // Normalize to parts-per-thousand scale
    if (value < 1) {
      value *= 1000; // Decimal fraction (0.916 → 916)
    } else if (value < 100) {
      value *= 10; // Percentage (91.6 → 916)
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

  String _formatPrice(double value) {
    final intVal = value.toInt();
    final str = intVal.toString();
    if (str.length <= 3) return '\u20B9$intVal';
    String result = str.substring(str.length - 3);
    int i = str.length - 3;
    while (i > 0) {
      final chunk = str.substring(i - 2 < 0 ? 0 : i - 2, i);
      result = '$chunk,$result';
      i -= 2;
    }
    return '\u20B9$result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,

      // =====================================================
      // PREMIUM BOTTOM ACTION BAR
      // =====================================================
      bottomNavigationBar: Get.find<AuthController>().isAdmin
          ? const SizedBox.shrink()
          : Obx(() {
              final quantity = cartController.getProductQuantity(
                _currentProduct.id,
              );
              final isInCart = quantity > 0;

              return SafeArea(
                child: Container(
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
                    context.getScreenHeight(1.5),
                    context.getResponsiveSize(4),
                    context.getScreenHeight(1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: context.getScreenHeight(6.2),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: isInCart ? 0 : 2,
                              shadowColor: AppColors.primaryGold.withValues(
                                alpha: 0.2,
                              ),
                              backgroundColor: isInCart
                                  ? Colors.grey.shade100
                                  : const Color(0xFFF9F6F0),
                              foregroundColor: isInCart
                                  ? Colors.grey
                                  : AppColors.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isInCart
                                      ? Colors.grey.shade300
                                      : AppColors.primaryGold.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            onPressed: isInCart
                                ? null
                                : () {
                                    cartController.addToCart(_currentProduct);
                                  },
                            child: Text(
                              isInCart ? 'Added to Cart' : 'Add to Cart',
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
                          height: context.getScreenHeight(6.2),
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
                              Navigator.of(context).pop();
                              Get.find<NavigationController>().switchTab(2);
                            },
                            child: Text(
                              'View Cart',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.5),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

      // =====================================================
      // MODERN CURVED BODY LAYOUT
      // =====================================================
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
          : SafeArea(child: _buildProductContent(widget.product)),
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

    final bool inStock = product.isActive;
    final String stockText = inStock ? "IN STOCK" : "OUT OF STOCK";
    final Color stockColor = inStock
        ? AppColors.primaryGold
        : Colors.red.shade600;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- 1. Image Section (scrolls with content) ---
            SizedBox(
              height: context.getScreenHeight(55),
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

                  // Top Left: Back Button
                  Positioned(
                    top: context.getScreenHeight(2),
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

                  // Top Right: Wishlist Heart
                  if (!Get.find<AuthController>().isAdmin)
                    Positioned(
                      top: context.getScreenHeight(2),
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

                  // Bottom Left: Ribbon Tags
                  Positioned(
                    bottom: context.getScreenHeight(8),
                    left: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                            bottom: context.getScreenHeight(0.8),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            context.getResponsiveSize(4),
                            context.getScreenHeight(0.6),
                            context.getResponsiveSize(3),
                            context.getScreenHeight(0.6),
                          ),
                          decoration: BoxDecoration(
                            color: stockColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(3, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.getResponsiveSize(3),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (netWeight != null)
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              context.getResponsiveSize(4),
                              context.getScreenHeight(0.6),
                              context.getResponsiveSize(3),
                              context.getScreenHeight(0.6),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(3, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            "Net Wt.: $netWeight g",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.getResponsiveSize(3.2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom Right: Zoom Icon
                  if (product.imageUrl != null)
                    Positioned(
                      bottom: context.getScreenHeight(8),
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

            // --- 2. Product Details (curved top, scrolls after image) ---
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(5),
                context.getScreenHeight(3),
                context.getResponsiveSize(5),
                context.getScreenHeight(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
                  Text(
                    product.name
                        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                        .replaceAll(
                          RegExp(r'collection', caseSensitive: false),
                          '',
                        )
                        .trim()
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(5.5),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2C3E50),
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(0.3)),

                  // Tag Number
                  Text(
                    "Tag: ${product.tagNo ?? rawData['Barcode'] ?? '-'}",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.2),
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(1)),

                  // Price
                  if (price != null &&
                      (Get.find<AuthController>().user?.isRetailer ==
                              true ||
                          Get.find<AuthController>().isAdmin))
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(4),
                        vertical: context.getScreenHeight(0.8),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            _formatPrice(price),
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(6),
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: context.getScreenHeight(1.5)),

                  // Specifications Header & Customize Button
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
                            vertical: context.getScreenHeight(0.8),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: context.getScreenHeight(1)),

                  // 2x2 Specifications Grid
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
                    SizedBox(height: context.getScreenHeight(1)),
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

                  SizedBox(height: context.getScreenHeight(1)),

                  // Size (Full Width)
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
                    SizedBox(height: context.getScreenHeight(1)),
                  ],

                  // 5th Specification (Full Width Collection Name)
                  SizedBox(
                    width: double.infinity,
                    child: _buildSpecBox(
                      context,
                      Icons.category_outlined,
                      "COLLECTION NAME",
                      collectionName,
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(1.5)),

                  // Description Header
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(4),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(0.5)),

                  // Dynamic Description Text
                  Text(
                    "Elegant ${product.name.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').replaceAll(RegExp(r'collection', caseSensitive: false), '').trim()} with fine craftsmanship, $purity purity, and a timeless design—perfect for pairing with traditional Indian ensembles or adding everyday elegance.",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.2),
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(1.5)),

                  // Trust Badges Box
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: context.getScreenHeight(1.2),
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
                  SizedBox(height: context.getScreenHeight(10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Enhanced Helper Widget for Grid and Full-Width Spec Boxes ---
  Widget _buildSpecBox(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(3),
        vertical: context.getScreenHeight(1),
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
                SizedBox(height: context.getScreenHeight(0.3)),
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

  // --- Helper Widget for Trust Badges ---
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
