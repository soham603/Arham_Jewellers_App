import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/navigation_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController cartController = Get.find<CartController>();

  bool get _isRetailer => Get.find<AuthController>().user?.isRetailer == true;

  String _formatPrice(num value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        titleSpacing: context.getScreenWidth(4),
        title: Text(
          'Cart',
          style: TextStyle(
            fontSize: context.getScreenWidth(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: context.getScreenWidth(4)),
              child: Center(
                child: Text(
                  '${cartController.totalItems} item${cartController.totalItems != 1 ? 's' : ''}',
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
                        final price =
                            (rawData["TagSalesAmount"] ?? 0).toDouble();
                        final imageURL = item.product.displayImageUrl;

                        return Dismissible(
                          key: ValueKey(item.product.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            cartController.removeFromCart(item.product.id);
                          },
                          background: Container(
                            margin: EdgeInsets.only(
                              bottom: context.getScreenHeight(1.2),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getScreenWidth(5),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE85D4F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: context.getScreenWidth(6),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Get.toNamed(
                                AppRoutes.details,
                                arguments: item.product,
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: context.getScreenHeight(1.2),
                              ),
                              padding: EdgeInsets.all(
                                context.getScreenWidth(3.5),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE9E2D8),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: context.getScreenWidth(26),
                                      height: context.getScreenWidth(26),
                                      color: const Color(0xFFF7F3EC),
                                      child: imageURL != null &&
                                              imageURL.trim().isNotEmpty &&
                                              Uri.tryParse(imageURL)
                                                      ?.hasAbsolutePath ==
                                                  true
                                          ? CachedNetworkImage(
                                              imageUrl: imageURL,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) {
                                                return Shimmer.fromColors(
                                                  baseColor:
                                                      const Color(0xFFE9E3DA),
                                                  highlightColor:
                                                      const Color(0xFFF6F2EC),
                                                  child: Container(
                                                      color: Colors.white),
                                                );
                                              },
                                              errorWidget:
                                                  (context, url, error) {
                                                return Center(
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color:
                                                        Colors.grey.shade500,
                                                    size:
                                                        context.getScreenWidth(
                                                            7),
                                                  ),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                color:
                                                    const Color(0xFF8C7E68),
                                                size:
                                                    context.getScreenWidth(7),
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: context.getScreenWidth(3.5)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize:
                                                context.getScreenWidth(4.2),
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (item.product.touch != null) ...[
                                          SizedBox(
                                              height:
                                                  context.getScreenHeight(0.4)),
                                          Text(
                                            item.product.touch!,
                                            style: TextStyle(
                                              fontSize:
                                                  context.getScreenWidth(3.4),
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                        if (item.product.grossWeight !=
                                            null) ...[
                                          SizedBox(
                                              height:
                                                  context.getScreenHeight(0.4)),
                                          Text(
                                            'Gross Wt: ${item.product.grossWeight}g',
                                            style: TextStyle(
                                              fontSize:
                                                  context.getScreenWidth(3.4),
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                        if (item.product.fineWeight !=
                                            null) ...[
                                          SizedBox(
                                              height:
                                                  context.getScreenHeight(0.4)),
                                          Text(
                                            'Fine Wt: ${item.product.fineWeight}g',
                                            style: TextStyle(
                                              fontSize:
                                                  context.getScreenWidth(3.4),
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                        if (item.product.size != null) ...[
                                          SizedBox(
                                              height:
                                                  context.getScreenHeight(0.4)),
                                          Text(
                                            item.product.size!,
                                            style: TextStyle(
                                              fontSize:
                                                  context.getScreenWidth(3.4),
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                        SizedBox(
                                            height:
                                                context.getScreenHeight(0.8)),
                                        if (_isRetailer)
                                          Text(
                                            "₹${_formatPrice(price)}",
                                            style: TextStyle(
                                              fontSize:
                                                  context.getScreenWidth(4.8),
                                              color: AppColors.primaryGold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        SizedBox(
                                            height:
                                                context.getScreenHeight(1)),
                                        _quantityControls(
                                          context,
                                          quantity: item.quantity,
                                          onDecrement: () {
                                            cartController.decrementQuantity(
                                              item.product.id,
                                            );
                                          },
                                          onIncrement: () {
                                            cartController.incrementQuantity(
                                              item.product.id,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: context.getScreenHeight(0.5)),
                      if (_isRetailer) _priceBreakdown(context),
                      SizedBox(height: context.getScreenHeight(2)),
                    ],
                  );
                }),
              ),
              Obx(() {
                if (cartController.items.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _actionButtons(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantityControls(
    BuildContext context, {
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      width: context.getScreenWidth(34),
      height: context.getScreenHeight(4.7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEDF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quantityButton(
            context,
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          Text(
            '$quantity',
            style: TextStyle(
              fontSize: context.getScreenWidth(4.3),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          _quantityButton(
            context,
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.getScreenWidth(7),
        height: context.getScreenWidth(7),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: context.getScreenWidth(3.8),
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _priceBreakdown(BuildContext context) {
    return Obx(() {
      final subtotal = cartController.subtotal;
      final gst = subtotal * 0.03;
      final total = subtotal + gst;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.getScreenWidth(5)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9E2D8)),
        ),
        child: Column(
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
            Container(height: 1, color: AppColors.divider),
            _breakdownRow(
              context,
              "Gold Value",
              "₹${_formatPrice(subtotal)}",
            ),
            _breakdownRow(
              context,
              "GST (3%)",
              "₹${_formatPrice(gst)}",
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.getScreenHeight(1.5),
              ),
              child: Container(height: 1, color: AppColors.divider),
            ),
            _breakdownRow(
              context,
              "TOTAL",
              "₹${_formatPrice(total)}",
              bold: true,
            ),
          ],
        ),
      );
    });
  }

  Widget _actionButtons(BuildContext context) {
    return Obx(() {
      final hasItems = cartController.items.isNotEmpty;

      return SizedBox(
        width: double.infinity,
        height: context.getScreenHeight(6.5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primaryGold,
            disabledBackgroundColor:
                AppColors.primaryGold.withOpacity(0.45),
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
            'Proceed to Enquiry',
            style: TextStyle(
              fontSize: context.getScreenWidth(5),
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
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
            SizedBox(height: context.getScreenHeight(3)),
            SizedBox(
              width: double.infinity,
              height: context.getScreenHeight(6),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Get.find<NavigationController>().switchTab(AppRoutes.tabIndexSearch);
                },
                child: Text(
                  'Browse Products',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(4.5),
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontSize: context.getScreenWidth(bold ? 4.3 : 4),
              color: bold ? AppColors.textDark : AppColors.textMuted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: context.getScreenWidth(bold ? 4.8 : 4.2),
              color: bold ? AppColors.primaryGold : AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
