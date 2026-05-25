import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/app_bottom_nav.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        titleSpacing: context.getScreenWidth(4),
        title: Row(
          children: [
            Container(
              width: context.getScreenWidth(10),
              height: context.getScreenWidth(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primaryGold,
                size: context.getScreenWidth(5.2),
              ),
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Text(
              'Cart',
              style: TextStyle(
                fontSize: context.getScreenWidth(5.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: context.getScreenWidth(4)),
              child: Center(
                child: Text(
                  '${cartController.totalItems} items',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(4),
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.getScreenWidth(4),
            context.getScreenHeight(1),
            context.getScreenWidth(4),
            context.getScreenHeight(1.5),
          ),
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (cartController.items.isEmpty) {
                    return _emptyCart(context);
                  }
        
                  return ListView(
                    children: [
                      ...List.generate(cartController.items.length, (index) {
                        final item = cartController.items[index];
                        final rawData = item.product.rawData ?? {};
                        final price = rawData["TagSalesAmount"] ?? 0;
        
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: context.getScreenHeight(1.3),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(context.getScreenWidth(3.5)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE9E2D8)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: context.getScreenWidth(26),
                                        height: context.getScreenWidth(26),
                                        color: const Color(0xFFF7F3EC),
                                        child: item.product.imageUrl != null &&
                                                item.product.imageUrl!
                                                    .trim()
                                                    .isNotEmpty &&
                                                Uri.tryParse(item.product.imageUrl!)
                                                        ?.hasAbsolutePath ==
                                                    true
                                            ? CachedNetworkImage(
                                                imageUrl: item.product.imageUrl!,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) {
                                                  return Shimmer.fromColors(
                                                    baseColor: const Color(0xFFE9E3DA),
                                                    highlightColor: const Color(0xFFF6F2EC),
                                                    child: Container(color: Colors.white),
                                                  );
                                                },
                                                errorWidget: (context, url, error) {
                                                  return Center(
                                                    child: Icon(
                                                      Icons.image_not_supported_outlined,
                                                      color: Colors.grey.shade500,
                                                      size: context.getScreenWidth(7),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: const Color(0xFF8C7E68),
                                                  size: context.getScreenWidth(7),
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: context.getScreenWidth(3.5)),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: context.getScreenWidth(9),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: context.getScreenWidth(4.2),
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark,
                                                height: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: context.getScreenHeight(0.7)),
                                            Text(
                                              "₹$price",
                                              style: TextStyle(
                                                fontSize: context.getScreenWidth(4.8),
                                                color: AppColors.primaryGold,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: context.getScreenHeight(1)),
                                            Container(
                                              width: context.getScreenWidth(34),
                                              height: context.getScreenHeight(4.7),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3EEDF),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      cartController.decrementQuantity(
                                                        item.product.id,
                                                      );
                                                    },
                                                    child: Container(
                                                      width: context.getScreenWidth(7),
                                                      height: context.getScreenWidth(7),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "−",
                                                          style: TextStyle(
                                                            fontSize:
                                                                context.getScreenWidth(5),
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.textDark,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.quantity}',
                                                    style: TextStyle(
                                                      fontSize: context.getScreenWidth(4.3),
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      cartController.incrementQuantity(
                                                        item.product.id,
                                                      );
                                                    },
                                                    child: Container(
                                                      width: context.getScreenWidth(7),
                                                      height: context.getScreenWidth(7),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "+",
                                                          style: TextStyle(
                                                            fontSize:
                                                                context.getScreenWidth(4.8),
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.textDark,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      cartController.removeFromCart(item.product.id);
                                    },
                                    child: Container(
                                      width: context.getScreenWidth(8.5),
                                      height: context.getScreenWidth(8.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE0E0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "×",
                                          style: TextStyle(
                                            fontSize: context.getScreenWidth(5.2),
                                            color: const Color(0xFFD35252),
                                            fontWeight: FontWeight.w700,
                                          ),
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
                      SizedBox(height: context.getScreenHeight(0.5)),
                      Container(
                        padding: EdgeInsets.all(context.getScreenWidth(5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE9E2D8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Obx(() {
                          final subtotal = cartController.subtotal;
                          final gst = subtotal * 0.03;
                          final total = subtotal + gst;
        
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price Breakdown',
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(5.1),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: context.getScreenHeight(1)),
                              Divider(color: Colors.grey.shade300),
                              _breakdownRow(
                                context,
                                "Gold Value",
                                "₹${subtotal.toStringAsFixed(0)}",
                              ),
                              _breakdownRow(
                                context,
                                "GST (3%)",
                                "₹${gst.toStringAsFixed(0)}",
                              ),
                              Divider(height: context.getScreenHeight(3)),
                              _breakdownRow(
                                context,
                                "TOTAL",
                                "₹${total.toStringAsFixed(0)}",
                                bold: true,
                              ),
                            ],
                          );
                        }),
                      ),
                      SizedBox(height: context.getScreenHeight(2)),
                    ],
                  );
                }),
              ),
              Obx(() {
                final hasItems = cartController.items.isNotEmpty;
        
                return SizedBox(
                  width: double.infinity,
                  height: context.getScreenHeight(6.5),
                  child: Opacity(
                    opacity: hasItems ? 1 : 0.45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: hasItems
                          ? () {
                              Get.toNamed(AppRoutes.checkout);
                            }
                          : null,
                      child: Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5),
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2),
    );
  }

  Widget _emptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.getScreenWidth(26),
              height: context.getScreenWidth(26),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: context.getScreenWidth(12),
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(height: context.getScreenHeight(2.2)),
            Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: context.getScreenWidth(5.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Text(
              "Add items to your cart to continue to checkout.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.8),
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(
    BuildContext context,
    String left,
    String right, {
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.5)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: TextStyle(
                fontSize: context.getScreenWidth(4.3),
                color: bold ? AppColors.textDark : AppColors.textMuted,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: context.getScreenWidth(4.5),
              color: bold ? AppColors.primaryGold : AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}