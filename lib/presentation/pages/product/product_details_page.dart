import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

// Import your new Customise Order Page here
import 'customise_order_page.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final CartController cartController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CartController>()) {
      cartController = Get.find<CartController>();
    } else {
      cartController = Get.put(CartController());
    }
  }

  // --- Zoom Dialog Function ---
  void _showZoomDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 1,
              maxScale: 4,
              child: Container(
                width: context.getScreenWidth(80),
                height: context.getScreenHeight(45),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -15,
              right: -15,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper to convert raw Touch/Purity to standard Karat ---
  String _getConvertedPurity(Map<String, dynamic> rawData, String? modelKarat) {
    if (modelKarat != null && modelKarat.isNotEmpty) return modelKarat;

    final touch =
        rawData["SalesTouch"]?.toString() ?? rawData["Touch"]?.toString();
    if (touch == "92" || touch == "91.6" || touch == "91.75") {
      return "22K";
    } else if (touch == "84" || touch == "83.3") {
      return "20K";
    } else if (touch == "75") {
      return "18K";
    } else if (touch != null) {
      return "${touch}K";
    }
    return "22K";
  }

  @override
  Widget build(BuildContext context) {
    final rawData = widget.product.rawData ?? {};
    final netWeight = rawData["FineWt"]?.toString() ?? "0.000";
    final grossWeight = rawData["GrossWt"]?.toString() ?? "0.000";
    final purity = _getConvertedPurity(rawData, widget.product.karat);
    final pieces = rawData["Pieces"]?.toString() ?? "1";
    final designName = rawData["DesignName"]?.toString() ?? "Standard";

    // Dynamic Stock Logic
    final bool inStock = widget.product.isActive;
    final String stockText = inStock ? "IN STOCK" : "OUT OF STOCK";
    final Color stockColor = inStock
        ? AppColors.primaryGold
        : Colors.red.shade600;

    return Scaffold(
      backgroundColor: AppColors.pageBg,

      // =====================================================
      // PREMIUM BOTTOM ACTION BAR
      // =====================================================
      bottomNavigationBar: Obx(() {
        final quantity = cartController.getProductQuantity(widget.product.id);
        final isInCart = quantity > 0;

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              context.getScreenWidth(4),
              context.getScreenHeight(1.5),
              context.getScreenWidth(4),
              context.getScreenHeight(1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: context.getScreenHeight(6.2),
                    child: isInCart
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getScreenWidth(3),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4D6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    cartController.decrementQuantity(
                                      widget.product.id,
                                    );
                                  },
                                  child: Container(
                                    height: context.getScreenWidth(9),
                                    width: context.getScreenWidth(9),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGold,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: context.getScreenWidth(4.5),
                                    ),
                                  ),
                                ),
                                Text(
                                  quantity.toString(),
                                  style: TextStyle(
                                    fontSize: context.getScreenWidth(5),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    cartController.addToCart(widget.product);
                                  },
                                  child: Container(
                                    height: context.getScreenWidth(9),
                                    width: context.getScreenWidth(9),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGold,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: context.getScreenWidth(4.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              shadowColor: AppColors.primaryGold.withOpacity(
                                0.2,
                              ),
                              backgroundColor: const Color(0xFFF9F6F0),
                              foregroundColor: AppColors.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.primaryGold.withOpacity(0.4),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            onPressed: () {
                              cartController.addToCart(widget.product);
                            },
                            child: Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: context.getScreenWidth(4.2),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                ),

                SizedBox(width: context.getScreenWidth(3)),
                Expanded(
                  child: SizedBox(
                    height: context.getScreenHeight(6.2),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 6,
                        shadowColor: AppColors.primaryGold.withOpacity(0.5),
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (!isInCart) {
                          cartController.addToCart(widget.product);
                        }
                        Get.toNamed(AppRoutes.cart);
                      },
                      child: Text(
                        'Buy Now',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(4.2),
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
      body: SafeArea(
        child: Stack(
          children: [
            // --- 1. Top Image Section ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: context.getScreenHeight(45),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFE6E1D9),
                    child:
                        widget.product.imageUrl != null &&
                            widget.product.imageUrl!.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: const Color(0xFFE7E2DB),
                              highlightColor: const Color(0xFFF5F1EB),
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: context.getScreenWidth(12),
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              '[ No Image ]',
                              style: TextStyle(
                                fontSize: context.getScreenWidth(5),
                                color: const Color(0xFF8C7E68),
                              ),
                            ),
                          ),
                  ),

                  // Top Left: Back Button Only
                  Positioned(
                    top: context.getScreenHeight(2),
                    left: context.getScreenWidth(4),
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(context.getScreenWidth(2.5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: context.getScreenWidth(5),
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Left: "Ribbon" Tags
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
                            context.getScreenWidth(4),
                            context.getScreenHeight(0.6),
                            context.getScreenWidth(3),
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
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.getScreenWidth(3),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            context.getScreenWidth(4),
                            context.getScreenHeight(0.6),
                            context.getScreenWidth(3),
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
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "Net Weight: $netWeight g",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.getScreenWidth(3.2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Right: Zoom Icon
                  if (widget.product.imageUrl != null)
                    Positioned(
                      bottom: context.getScreenHeight(8),
                      right: context.getScreenWidth(4),
                      child: GestureDetector(
                        onTap: () =>
                            _showZoomDialog(context, widget.product.imageUrl!),
                        child: Container(
                          padding: EdgeInsets.all(context.getScreenWidth(2.5)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.open_in_full,
                            size: context.getScreenWidth(5),
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- 2. Curved Bottom Sheet (Details) ---
            Positioned(
              top: context.getScreenHeight(40),
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    context.getScreenWidth(5),
                    context.getScreenHeight(3),
                    context.getScreenWidth(5),
                    context.getScreenHeight(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        widget.product.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: context.getScreenWidth(6.5),
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2C3E50),
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(0.5)),

                      // Tag Number
                      Text(
                        "Tag: ${widget.product.tagNo ?? rawData['Barcode'] ?? '-'}",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.8),
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(2.5)),

                      // Specifications Header & Customize Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Specification",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(5),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // 🔥 Route to Customise Order Page
                              Get.to(
                                () =>
                                    CustomiseOrderPage(product: widget.product),
                              );
                            },
                            icon: Icon(
                              Icons.tune,
                              size: context.getScreenWidth(4),
                              color: Colors.white,
                            ),
                            label: Text(
                              "Customize",
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.2),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              elevation: 3,
                              shadowColor: AppColors.primaryGold.withOpacity(
                                0.4,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.getScreenWidth(4),
                                vertical: context.getScreenHeight(0.8),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getScreenHeight(2)),

                      // 2x2 Specifications Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildSpecBox(
                              context,
                              Icons.scale_outlined,
                              "NET WEIGHT",
                              "$netWeight g",
                            ),
                          ),
                          SizedBox(width: context.getScreenWidth(3)),
                          Expanded(
                            child: _buildSpecBox(
                              context,
                              Icons.work_outline,
                              "GROSS WEIGHT",
                              "$grossWeight g",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.getScreenHeight(1.5)),
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
                          SizedBox(width: context.getScreenWidth(3)),
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

                      SizedBox(height: context.getScreenHeight(1.5)),

                      // 5th Specification (Full Width Design Name)
                      SizedBox(
                        width: double.infinity,
                        child: _buildSpecBox(
                          context,
                          Icons.brush_outlined,
                          "DESIGN NAME",
                          designName,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(3)),

                      // Description Header
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(1)),

                      // Dynamic Description Text
                      Text(
                        "Elegant ${widget.product.name} with fine craftsmanship, $purity purity, and a timeless design—perfect for pairing with traditional Indian ensembles or adding everyday elegance.",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.8),
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(3)),

                      // Trust Badges Box
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: context.getScreenHeight(2),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTrustBadge(
                              context,
                              Icons.local_shipping_outlined,
                              "Pan-India\nShipping",
                            ),
                            _buildTrustBadge(
                              context,
                              Icons.verified_outlined,
                              "Certified\nQuality",
                            ),
                            _buildTrustBadge(
                              context,
                              Icons.star_border,
                              "Premium\nFinish",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
        horizontal: context.getScreenWidth(3),
        vertical: context.getScreenHeight(1.5),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGold.withOpacity(0.8),
            size: context.getScreenWidth(6),
          ),
          SizedBox(width: context.getScreenWidth(2.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.getScreenWidth(2.6),
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.getScreenHeight(0.3)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3.8),
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
      children: [
        Icon(
          icon,
          color: AppColors.primaryGold.withOpacity(0.7),
          size: context.getScreenWidth(5),
        ),
        SizedBox(width: context.getScreenWidth(1.5)),
        Text(
          text,
          style: TextStyle(
            fontSize: context.getScreenWidth(3),
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
