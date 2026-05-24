import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserOrderController orderController =
        Get.isRegistered<UserOrderController>()
            ? Get.find<UserOrderController>()
            : Get.put(UserOrderController());

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top gold accent bar (matches Figma TopAccent) ──────────
            Container(height: 4, color: AppColors.primaryGold),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(5),
                  vertical: context.getScreenHeight(3),
                ),
                child: Obx(() {
                  final orderId = orderController.createdOrderId;
                  final message = orderController.orderMessage;

                  return Column(
                    children: [
                      SizedBox(height: context.getScreenHeight(4)),

                      // ── Success icon circle ──────────────────────────
                      Container(
                        width: context.getScreenWidth(28),
                        height: context.getScreenWidth(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primaryGold,
                            size: context.getScreenWidth(14),
                          ),
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(3)),

                      // ── "Order Placed!" heading ──────────────────────
                      Text(
                        'Order Placed!',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(7),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: context.getScreenHeight(1)),

                      Text(
                        message.isNotEmpty
                            ? message
                            : 'Your order has been received.\nOur team will contact you shortly.',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.8),
                          color: AppColors.textMuted,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: context.getScreenHeight(4)),

                      // ── Order details card ───────────────────────────
                      _OrderDetailCard(
                        orderId: orderId,
                        context: context,
                      ),

                      SizedBox(height: context.getScreenHeight(3)),

                      // ── What happens next section ────────────────────
                      _NextStepsCard(context: context),

                      SizedBox(height: context.getScreenHeight(4)),

                      // ── View My Orders button ────────────────────────
                      SizedBox(
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
                          onPressed: () =>
                              Get.offAllNamed(AppRoutes.myOrders),
                          child: Text(
                            'View My Orders',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(1.5)),

                      // ── Continue Shopping button ─────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: context.getScreenHeight(6.5),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryGold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            foregroundColor: AppColors.primaryGold,
                          ),
                          onPressed: () => Get.offAllNamed(AppRoutes.home),
                          child: Text(
                            'Continue Shopping',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(2)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Detail Info Card ──────────────────────────────────────────────────

class _OrderDetailCard extends StatelessWidget {
  final String orderId;
  final BuildContext context;

  const _OrderDetailCard({required this.orderId, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail placeholder (matches Figma "Thumb") ───────────
          Row(
            children: [
              Container(
                width: context.getScreenWidth(18),
                height: context.getScreenWidth(18),
                decoration: BoxDecoration(
                  color: AppColors.tileBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primaryGold,
                    size: context.getScreenWidth(9),
                  ),
                ),
              ),
              SizedBox(width: context.getScreenWidth(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Confirmed',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(4.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: context.getScreenHeight(0.5)),
                    Text(
                      'Processing your request',
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

          if (orderId.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(2)),
            Container(height: 1, color: AppColors.divider),
            SizedBox(height: context.getScreenHeight(2)),

            _infoRow(
              context,
              label: 'Order ID',
              value: '#$orderId',
              valueColor: AppColors.primaryGold,
              bold: true,
            ),
          ],

          SizedBox(height: context.getScreenHeight(1.2)),

          _infoRow(
            context,
            label: 'Status',
            value: 'Pending Confirmation',
            valueWidget: _StatusBadge(
              label: 'Pending',
              color: const Color(0xFFF5A623),
              bgColor: const Color(0xFFFFF4E0),
            ),
          ),

          SizedBox(height: context.getScreenHeight(1.2)),

          _infoRow(
            context,
            label: 'Expected Contact',
            value: 'Within 24 hours',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.getScreenWidth(3.8),
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.8),
                color: valueColor ?? AppColors.textDark,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
      ],
    );
  }
}

// ── Next Steps Card ─────────────────────────────────────────────────────────

class _NextStepsCard extends StatelessWidget {
  final BuildContext context;
  const _NextStepsCard({required this.context});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.phone_in_talk_rounded, 'Team will call you',
          'Our team will contact you within 24 hours'),
      (Icons.verified_outlined, 'Order verification',
          'We confirm stock availability and pricing'),
      (Icons.local_shipping_outlined, 'Delivery or Pickup',
          'Choose home delivery or visit our showroom'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What happens next?",
            style: TextStyle(
              fontSize: context.getScreenWidth(4.5),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final (icon, title, subtitle) = entry.value;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.getScreenWidth(9),
                      height: context.getScreenWidth(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withOpacity(0.1),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.primaryGold,
                        size: context.getScreenWidth(4.5),
                      ),
                    ),
                    SizedBox(width: context.getScreenWidth(3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.4)),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.4),
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (idx < steps.length - 1)
                  Padding(
                    padding: EdgeInsets.only(
                      left: context.getScreenWidth(4.2),
                      top: context.getScreenHeight(0.8),
                      bottom: context.getScreenHeight(0.8),
                    ),
                    child: Container(
                      width: 1,
                      height: context.getScreenHeight(2),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.getScreenWidth(3.2),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
