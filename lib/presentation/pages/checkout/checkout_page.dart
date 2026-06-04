import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CartController cartController = Get.find<CartController>();
  late final UserOrderController userOrderController;

  bool get _isRetailer => Get.find<AuthController>().user?.isRetailer == true;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserOrderController>()) {
      userOrderController = Get.find<UserOrderController>();
    } else {
      userOrderController = Get.put(UserOrderController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,

        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getScreenWidth(5),
          ),
        ),

        title: Text(
          "Checkout",
          style: TextStyle(
            fontSize: context.getScreenWidth(6),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),

      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1),
          ),

          child: Obx(() {
            final items = cartController.items;
            final totalItems = cartController.totalItems;
            final subtotal = cartController.subtotal;
            final gst = subtotal * 0.03;
            final total = subtotal + gst;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.getScreenHeight(1)),

                Text(
                  "Booking Summary",
                  style: TextStyle(
                    fontSize: context.getScreenWidth(5.5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),

                SizedBox(height: context.getScreenHeight(0.5)),

                Text(
                  "$totalItems item${totalItems != 1 ? 's' : ''} in your booking",
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3.8),
                    color: AppColors.textMuted,
                  ),
                ),

                SizedBox(height: context.getScreenHeight(2)),

                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final rawData = item.product.rawData ?? {};
                  final price = (rawData["TagSalesAmount"] ?? 0).toDouble();
                  final itemTotal = price * item.quantity;
                  final imageURL = item.product.displayImageUrl;

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: context.getScreenHeight(1.2),
                    ),
                    padding: EdgeInsets.all(context.getScreenWidth(3.5)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7DED2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: context.getScreenWidth(20),
                            height: context.getScreenWidth(20),
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
                                        baseColor: const Color(0xFFE9E3DA),
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
                        SizedBox(width: context.getScreenWidth(3)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(4),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: context.getScreenHeight(0.5)),
                              if (item.product.karat != null)
                                Text(
                                  item.product.karat!,
                                  style: TextStyle(
                                    fontSize: context.getScreenWidth(3.4),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              SizedBox(height: context.getScreenHeight(0.8)),
                              if (_isRetailer)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₹${price.toStringAsFixed(0)} × ${item.quantity}",
                                      style: TextStyle(
                                        fontSize: context.getScreenWidth(3.6),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      "₹${itemTotal.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontSize: context.getScreenWidth(4.2),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (_isRetailer)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.getScreenWidth(4)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7DED2)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow(
                          context,
                          "Subtotal",
                          "₹${subtotal.toStringAsFixed(0)}",
                        ),
                        SizedBox(height: context.getScreenHeight(0.8)),
                        _summaryRow(
                          context,
                          "GST (3%)",
                          "₹${gst.toStringAsFixed(0)}",
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.getScreenHeight(1),
                          ),
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE7DED2),
                          ),
                        ),
                        _summaryRow(
                          context,
                          "Total",
                          "₹${total.toStringAsFixed(0)}",
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: context.getScreenHeight(3)),
              ],
            );
          }),
        ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            context.getScreenWidth(4),
            context.getScreenHeight(1),
            context.getScreenWidth(4),
            context.getScreenHeight(1),
          ),

          decoration: const BoxDecoration(color: Colors.white),

          child: SizedBox(
            width: double.infinity,
            height: context.getScreenHeight(6.5),

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor: AppColors.primaryGold,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              onPressed: () async {
                if (userOrderController.isCreatingOrder) return;

                final shouldPlaceOrder = await Get.dialog<bool>(
                  Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.symmetric(
                      horizontal: context.getScreenWidth(6),
                    ),

                    child: Container(
                      padding: EdgeInsets.all(context.getScreenWidth(5)),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: context.getScreenWidth(18),
                            height: context.getScreenWidth(18),

                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primaryGold,
                              size: context.getScreenWidth(8),
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(2)),

                          Text(
                            "Place Booking?",
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: context.getScreenWidth(5.5),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(1)),

                          Text(
                            "Are you sure you want to place this booking?\nOnce submitted, our team will contact you shortly.",
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.8),
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(3)),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: context.getScreenHeight(5.8),

                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),

                                    onPressed: () {
                                      Get.back(result: false);
                                    },

                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontSize: context.getScreenWidth(4),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: context.getScreenWidth(3)),

                              Expanded(
                                child: SizedBox(
                                  height: context.getScreenHeight(5.8),

                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: AppColors.primaryGold,

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),

                                    onPressed: () {
                                      Get.back(result: true);
                                    },

                                    child: Text(
                                      "Book Now",
                                      style: TextStyle(
                                        fontSize: context.getScreenWidth(4),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (shouldPlaceOrder == true) {
                  final success = await userOrderController.createOrder();
                  if (success) {
                    Get.offAllNamed(AppRoutes.orderSuccess);
                  }
                }
              },

              child: Obx(() {
                return userOrderController.isCreatingOrder
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: context.getScreenWidth(4.5),
                            height: context.getScreenWidth(4.5),

                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(width: context.getScreenWidth(3)),

                          Text(
                            "Booking...",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4.3),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Book Now",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(4.5),
                          fontWeight: FontWeight.w700,
                        ),
                      );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String left, String right) {
    final isTotal = left == "Total";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: TextStyle(
            fontSize: context.getScreenWidth(isTotal ? 4.2 : 3.9),
            color: isTotal ? AppColors.textDark : AppColors.textMuted,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: context.getScreenWidth(isTotal ? 4.5 : 4),
            color: isTotal ? AppColors.primaryGold : AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
