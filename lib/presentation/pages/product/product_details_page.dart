import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

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

  @override
  Widget build(BuildContext context) {
    final rawData = widget.product.rawData ?? {};

    return Scaffold(
      backgroundColor: AppColors.pageBg,

      bottomNavigationBar: Obx(() {
        final quantity = cartController.getProductQuantity(widget.product.id);

        final isInCart = quantity > 0;

        return SafeArea(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              context.getScreenWidth(4),
              context.getScreenHeight(1.2),
              context.getScreenWidth(4),
              context.getScreenHeight(1.2),
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
                              elevation: 0,
                              backgroundColor: const Color(0xFFE5DED5),
                              foregroundColor: AppColors.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                        elevation: 0,
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
                          fontWeight: FontWeight.w700,
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

      body: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // IMAGE SECTION
            // =====================================================
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE6E1D9),
                    child:
                        widget.product.imageUrl != null &&
                            widget.product.imageUrl!.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.contain,

                            placeholder: (context, url) {
                              return Shimmer.fromColors(
                                baseColor: const Color(0xFFE7E2DB),
                                highlightColor: const Color(0xFFF5F1EB),
                                child: Container(color: Colors.white),
                              );
                            },

                            errorWidget: (context, url, error) {
                              return Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: context.getScreenWidth(12),
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              '[ Product Image ]',
                              style: TextStyle(
                                fontSize: context.getScreenWidth(5),
                                color: const Color(0xFF8C7E68),
                              ),
                            ),
                          ),
                  ),

                  // =================================================
                  // BACK BUTTON
                  // =================================================
                  Positioned(
                    top: context.getScreenHeight(2),
                    left: context.getScreenWidth(4),
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.all(context.getScreenWidth(2.5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: context.getScreenWidth(4),
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // IMAGE INDICATORS
                  // =================================================
                  Positioned(
                    bottom: context.getScreenHeight(1.5),
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: context.getScreenWidth(1),
                          ),
                          width: index == 1 ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == 1
                                ? AppColors.primaryGold
                                : Colors.brown.shade200,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // DETAILS SECTION
            // =====================================================
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: AppColors.pageBg),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    context.getScreenWidth(5),
                    context.getScreenHeight(2),
                    context.getScreenWidth(5),
                    context.getScreenHeight(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =============================================
                      // PRODUCT NAME
                      // =============================================
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: context.getScreenWidth(7),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(0.8)),

                      // =============================================
                      // REVIEWS
                      // =============================================
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: const Color(0xFFF4B400),
                            size: context.getScreenWidth(4.5),
                          ),

                          SizedBox(width: context.getScreenWidth(1)),

                          Text(
                            "4.8",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4),
                              color: AppColors.textDark,
                            ),
                          ),

                          SizedBox(width: context.getScreenWidth(1.5)),

                          Text(
                            "(124 reviews)",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.8),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getScreenHeight(1)),

                      // =============================================
                      // PRICE
                      // =============================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹ ${rawData["NetAmt"] ?? "12,450"}",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(8),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGold,
                            ),
                          ),

                          SizedBox(width: context.getScreenWidth(2)),

                          Padding(
                            padding: EdgeInsets.only(
                              bottom: context.getScreenHeight(0.6),
                            ),
                            child: Text(
                              "(incl. making charges)",
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.4),
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getScreenHeight(1.2)),

                      Divider(color: Colors.grey.shade300),

                      SizedBox(height: context.getScreenHeight(1)),

                      // =============================================
                      // PRODUCT DETAILS TITLE
                      // =============================================
                      Text(
                        "Product Details",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5.5),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(1.2)),

                      // =============================================
                      // DETAILS
                      // =============================================
                      _detailRow(
                        context,
                        "Purity",
                        widget.product.karat ??
                            "${rawData["SalesTouch"] ?? ""}K",
                      ),

                      _detailRow(
                        context,
                        "Weight",
                        "${rawData["FineWt"] ?? "-"} grams",
                      ),

                      _detailRow(
                        context,
                        "Making Charges",
                        "₹${rawData["LabourAmt"] ?? 0}",
                      ),

                      _detailRow(
                        context,
                        "Design",
                        rawData["DesignName"] ?? "-",
                      ),

                      _detailRow(
                        context,
                        "Category",
                        widget.product.category?.name ?? "-",
                      ),

                      SizedBox(height: context.getScreenHeight(2)),

                      // =============================================
                      // REVIEWS
                      // =============================================
                      Text(
                        "Reviews",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5.5),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(1)),

                      Text(
                        "⭐⭐⭐⭐⭐ 4.8 out of 5",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(4.5),
                          color: AppColors.textDark,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(0.4)),

                      Text(
                        "Based on 124 reviews",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.6),
                          color: AppColors.textMuted,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(2)),
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

  Widget _detailRow(BuildContext context, String left, String right) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.7)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: TextStyle(
                fontSize: context.getScreenWidth(4),
                color: AppColors.textMuted,
              ),
            ),
          ),

          SizedBox(width: context.getScreenWidth(4)),

          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: context.getScreenWidth(4),
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
