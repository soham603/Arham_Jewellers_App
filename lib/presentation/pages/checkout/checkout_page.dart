import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/utils/formatters.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
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
    userOrderController = Get.isRegistered<UserOrderController>()
        ? Get.find<UserOrderController>()
        : Get.put(UserOrderController(), permanent: true);
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
            size: context.getResponsiveSize(5),
          ),
        ),

        title: Text(
          'Checkout',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        titleSpacing: context.getResponsiveSize(4),
      ),

      body: ResponsiveWrapper(
          child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(4),
            vertical: context.heightPercent(1),
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
                SizedBox(height: context.heightPercent(1)),

                Text(
                  "Booking Summary",
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4.5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),

                SizedBox(height: context.heightPercent(0.3)),

                Text(
                   "$totalItems item${totalItems != 1 ? 's' : ''} in your booking",
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.4),
                    color: AppColors.textMuted,
                  ),
                ),

                SizedBox(height: context.heightPercent(1.5)),

                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final price = GoldRateController.calculatePrice(
                    fineWeight: item.product.karigarNetWt ?? 0,
                    ratePer10Gram: Get.find<GoldRateController>().currentRate?.rate ?? 0,
                  );
                  final itemTotal = (price ?? 0) * item.quantity;
                  final imageURL = item.product.displayImageUrl;

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: context.heightPercent(0.8),
                    ),
                    padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7DED2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: context.getResponsiveSize(18),
                            height: context.getResponsiveSize(18),
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
                                          size: context.getResponsiveSize(6),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: const Color(0xFF8C7E68),
                                      size: context.getResponsiveSize(6),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: context.getResponsiveSize(2)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.6),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: context.heightPercent(0.2)),
                              if (item.product.touch != null)
                                Text(
                                  item.product.touch!,
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.0),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              if (item.product.grossWeight != null)
                                Text(
                                  'Gross Wt: ${item.product.grossWeight}g',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.0),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              if (item.product.karigarNetWt != null)
                                Text(
                                  'Net Wt: ${item.product.karigarNetWt}g',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.0),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              if (item.product.size != null)
                                Text(
                                  item.product.size!,
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.0),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              SizedBox(height: context.heightPercent(0.4)),
                              Text(
                                'Qty: ${item.quantity}',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.0),
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (_isRetailer)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${formatPrice(price ?? 0)} × ${item.quantity}",
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(3.2),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      "₹${formatAmount(itemTotal)}",
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(3.8),
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
                    padding: EdgeInsets.all(context.getResponsiveSize(3)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7DED2)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow(
                          context,
                          "Subtotal",
                          "₹${formatAmount(subtotal)}",
                        ),
                        SizedBox(height: context.heightPercent(0.5)),
                        _summaryRow(
                          context,
                          "GST (3%)",
                          "₹${formatAmount(gst)}",
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.heightPercent(0.6),
                          ),
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE7DED2),
                          ),
                        ),
                        _summaryRow(
                          context,
                          "Total",
                          "₹${formatAmount(total)}",
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: context.heightPercent(2)),
              ],
            );
          }),
        ),
      ),

        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(4),
            context.heightPercent(0.8),
            context.getResponsiveSize(4),
            context.heightPercent(0.8),
          ),

          decoration: const BoxDecoration(color: Colors.white),

          child: SizedBox(
            width: double.infinity,
            height: context.heightPercent(5),

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor: AppColors.primaryGold,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              onPressed: () async {
                if (userOrderController.isCreatingOrder) return;

                final shouldPlaceOrder = await Get.dialog<bool>(
                  Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(6),
                    ),

                    child: Container(
                      padding: EdgeInsets.all(context.getResponsiveSize(5)),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: context.getResponsiveSize(18),
                            height: context.getResponsiveSize(18),

                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primaryGold,
                              size: context.getResponsiveSize(8),
                            ),
                          ),

                          SizedBox(height: context.heightPercent(2)),

                          Text(
                            "Place Booking?",
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: context.getResponsiveSize(5.5),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),

                          SizedBox(height: context.heightPercent(1)),

                          Text(
                            "Once submitted, our team will contact you shortly.",
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.8),
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: context.heightPercent(3)),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: context.heightPercent(5),

                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),

                                    onPressed: () {
                                      Get.back(result: false);
                                    },

                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(3.8),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: context.getResponsiveSize(3)),

                              Expanded(
                                child: SizedBox(
                                  height: context.heightPercent(5),

                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: AppColors.primaryGold,

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),

                                    onPressed: () {
                                      Get.back(result: true);
                                    },

                                    child: Text(
                                      "Book Now",
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(3.8),
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
                  try {
                    final success = await userOrderController.createOrder();
                    if (success) {
                      Get.offAllNamed(AppRoutes.orderSuccess);
                    }
                  } catch (e, stackTrace) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to place order. Please try again.')),
                      );
                    }
                  }
                }
              },

              child: Obx(() {
                return userOrderController.isCreatingOrder
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: context.getResponsiveSize(4.5),
                            height: context.getResponsiveSize(4.5),

                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(width: context.getResponsiveSize(3)),

                          Text(
                            "Booking...",
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(4.3),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Book Now",
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(4.2),
                          fontWeight: FontWeight.w700,
                        ),
                      );
              }),
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
            fontSize: context.getResponsiveSize(isTotal ? 4.2 : 3.9),
            color: isTotal ? AppColors.textDark : AppColors.textMuted,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: context.getResponsiveSize(isTotal ? 4.5 : 4),
            color: isTotal ? AppColors.primaryGold : AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
