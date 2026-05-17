import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CartController cartController = Get.find<CartController>();
  late final UserOrderController userOrderController;

  int selectedDelivery = 0;
  int selectedPayment = 0;

  final List<String> paymentMethods = [
    "UPI",
    "Cash On Delivery",
    "Store Visit",
  ];

  final List<String> paymentSubtitles = [
    "GPay / PhonePe / Paytm",
    "Pay when order confirmed",
    "Pay directly at showroom",
  ];

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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  SizedBox(width: context.getScreenWidth(1.5)),

                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9CBB7),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  SizedBox(width: context.getScreenWidth(1.5)),

                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9CBB7),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.getScreenHeight(0.8)),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stepText(context, "Address", true),

                  _stepText(context, "Delivery", false),

                  _stepText(context, "Payment", false),
                ],
              ),

              SizedBox(height: context.getScreenHeight(2.2)),
              _sectionContainer(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontSize: context.getScreenWidth(5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(1.5)),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.getScreenWidth(3.5)),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF6),

                        borderRadius: BorderRadius.circular(16),

                        border: Border.all(color: const Color(0xFFE7DED2)),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  context.getScreenWidth(1.5),
                                ),

                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(
                                    0.12,
                                  ),

                                  shape: BoxShape.circle,
                                ),

                                child: Icon(
                                  Icons.home_rounded,
                                  color: AppColors.primaryGold,
                                  size: context.getScreenWidth(4),
                                ),
                              ),

                              SizedBox(width: context.getScreenWidth(2.5)),

                              Expanded(
                                child: Text(
                                  "Home",
                                  style: TextStyle(
                                    fontSize: context.getScreenWidth(4.4),

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: context.getScreenHeight(1)),

                          Text(
                            "Ratnesh Gold, Mumbai, Maharashtra - 400001",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.6),

                              color: AppColors.textMuted,

                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(1.5)),

                    SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(5.5),

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,

                          backgroundColor: const Color(0xFFF3ECE2),

                          foregroundColor: AppColors.primaryGold,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        onPressed: () {},

                        child: Text(
                          "+ Add New Address",
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4),

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(2)),

              Text(
                "Delivery Method",
                style: TextStyle(
                  fontSize: context.getScreenWidth(5.2),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: context.getScreenHeight(1)),

              _radioCard(
                context,
                title: "Home Delivery",
                subtitle: "Free • 2-4 working days",
                selected: selectedDelivery == 0,
                onTap: () {
                  setState(() {
                    selectedDelivery = 0;
                  });
                },
              ),

              SizedBox(height: context.getScreenHeight(1)),

              _radioCard(
                context,
                title: "Store Pickup",
                subtitle: "Ready for pickup today",
                selected: selectedDelivery == 1,
                onTap: () {
                  setState(() {
                    selectedDelivery = 1;
                  });
                },
              ),

              SizedBox(height: context.getScreenHeight(2.2)),

              // =====================================================
              // PAYMENT
              // =====================================================
              Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: context.getScreenWidth(5.2),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: context.getScreenHeight(1)),

              ...List.generate(paymentMethods.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: context.getScreenHeight(1)),

                  child: _radioCard(
                    context,
                    title: paymentMethods[index],
                    subtitle: paymentSubtitles[index],
                    selected: selectedPayment == index,
                    onTap: () {
                      setState(() {
                        selectedPayment = index;
                      });
                    },
                  ),
                );
              }),

              SizedBox(height: context.getScreenHeight(2)),

              // =====================================================
              // ORDER SUMMARY
              // =====================================================
              _sectionContainer(
                context,
                child: Obx(() {
                  final totalItems = cartController.totalItems;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Summary",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5),

                          fontWeight: FontWeight.w700,

                          color: AppColors.textDark,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(1.5)),

                      _summaryRow(context, "Products", "$totalItems Items"),

                      SizedBox(height: context.getScreenHeight(0.8)),

                      _summaryRow(
                        context,
                        "Delivery",
                        selectedDelivery == 0
                            ? "Home Delivery"
                            : "Store Pickup",
                      ),

                      SizedBox(height: context.getScreenHeight(0.8)),

                      _summaryRow(
                        context,
                        "Payment",
                        paymentMethods[selectedPayment],
                      ),
                    ],
                  );
                }),
              ),

              SizedBox(height: context.getScreenHeight(3)),
            ],
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
                            "Place Order?",
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: context.getScreenWidth(5.5),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(1)),

                          Text(
                            "Are you sure you want to place this order?\nOnce submitted, our team will contact you shortly.",
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
                                      "Place Order",
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
                  await userOrderController.createOrder();
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
                            "Placing Order...",
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4.3),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Place Order",
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

  Widget _stepText(BuildContext context, String title, bool active) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.getScreenWidth(3.2),
        fontWeight: FontWeight.w600,
        color: active ? AppColors.primaryGold : AppColors.textMuted,
      ),
    );
  }

  Widget _sectionContainer(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(context.getScreenWidth(4)),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFE7DED2)),
      ),

      child: child,
    );
  }

  // ===========================================================
  // RADIO CARD
  // ===========================================================

  Widget _radioCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        padding: EdgeInsets.all(context.getScreenWidth(4)),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: selected ? AppColors.primaryGold : const Color(0xFFE3DDD5),

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              width: context.getScreenWidth(5),
              height: context.getScreenWidth(5),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: selected
                      ? AppColors.primaryGold
                      : const Color(0xFFC8B79D),
                  width: 1.5,
                ),
              ),

              child: selected
                  ? Center(
                      child: Container(
                        width: context.getScreenWidth(2.3),

                        height: context.getScreenWidth(2.3),

                        decoration: const BoxDecoration(
                          color: AppColors.primaryGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),

            SizedBox(width: context.getScreenWidth(3)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(4.2),

                      fontWeight: FontWeight.w700,

                      color: AppColors.textDark,
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(0.4)),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.5),

                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // SUMMARY ROW
  // ===========================================================

  Widget _summaryRow(BuildContext context, String left, String right) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              fontSize: context.getScreenWidth(3.9),
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Text(
          right,
          style: TextStyle(
            fontSize: context.getScreenWidth(4),
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
