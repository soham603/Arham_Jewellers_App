import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAllNamed(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: SafeArea(
          child: Column(
            children: [
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

                        Text(
                          'Booking Confirmed!',
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
                              : 'Your booking has been received.\nOur team will contact you shortly.',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(3.8),
                            color: AppColors.textMuted,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: context.getScreenHeight(4)),

                        _OrderDetailCard(
                          orderId: orderId,
                          images: orderController.lastOrderImages,
                          itemNames: orderController.lastOrderItemNames,
                          itemQuantities: orderController.lastOrderItemQuantities,
                          itemPrices: orderController.lastOrderItemPrices,
                          total: orderController.lastOrderTotal,
                          createdAt: orderController.lastOrderCreatedAt,
                          context: context,
                        ),

                        SizedBox(height: context.getScreenHeight(3)),

                        _NextStepsCard(context: context),

                        SizedBox(height: context.getScreenHeight(4)),

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
      ),
    );
  }
}

// ── Order Detail Info Card ──────────────────────────────────────────────────

class _OrderDetailCard extends StatelessWidget {
  final String orderId;
  final List<String> images;
  final List<String> itemNames;
  final List<int> itemQuantities;
  final List<double> itemPrices;
  final double total;
  final DateTime createdAt;
  final BuildContext context;

  const _OrderDetailCard({
    required this.orderId,
    required this.images,
    required this.itemNames,
    required this.itemQuantities,
    required this.itemPrices,
    required this.total,
    required this.createdAt,
    required this.context,
  });

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
          // ── Thumbnail (product images or fallback) ────────────────
          Row(
            children: [
              _buildThumbnail(context),
              SizedBox(width: context.getScreenWidth(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Received',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(4.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: context.getScreenHeight(0.5)),
                    Text(
                      'Your booking has been received',
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
              valueWidget: _CopyableOrderId(orderId: orderId),
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

          if (itemNames.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(2)),
            Container(height: 1, color: AppColors.divider),
            SizedBox(height: context.getScreenHeight(2)),

            for (int i = 0; i < itemNames.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${itemNames[i]}  x${itemQuantities[i]}',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.6),
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${itemPrices[i].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.6),
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (i < itemNames.length - 1)
                SizedBox(height: context.getScreenHeight(1)),
            ],

            SizedBox(height: context.getScreenHeight(1.5)),
            Container(height: 1, color: AppColors.divider),
            SizedBox(height: context.getScreenHeight(1.5)),

            Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(4.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(4.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: context.getScreenHeight(1.5)),
          Container(height: 1, color: AppColors.divider),
          SizedBox(height: context.getScreenHeight(1.5)),

          _infoRow(
            context,
            label: 'Booked On',
            value: DateFormat('dd MMM yyyy • hh:mm a').format(createdAt.toLocal()),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final size = context.getScreenWidth(18);
    final displayImages = images.take(3).toList();

    if (displayImages.isEmpty) {
      return Container(
        width: size,
        height: size,
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
      );
    }

    if (displayImages.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: displayImages[0],
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              color: AppColors.tileBg,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, _, _) => RatneshFallback.s(),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (int i = displayImages.length - 1; i >= 0; i--)
            Positioned(
              top: i * 3.0,
              left: i * 3.0,
              child: Container(
                width: size - (displayImages.length - 1) * 3.0,
                height: size - (displayImages.length - 1) * 3.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: displayImages[i],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.tileBg,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, _, _) => RatneshFallback.s(),
                  ),
                ),
              ),
            ),
          if (images.length > displayImages.length)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  "+${images.length - displayImages.length}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.getScreenWidth(2.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
    final valueChild = valueWidget ??
        Text(
          value ?? '',
          style: TextStyle(
            fontSize: context.getScreenWidth(3.8),
            color: valueColor ?? AppColors.textDark,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.getScreenWidth(3.8),
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: valueChild),
      ],
    );
  }
}

// ── Copyable Order ID ────────────────────────────────────────────────────────

class _CopyableOrderId extends StatefulWidget {
  final String orderId;
  const _CopyableOrderId({required this.orderId});

  @override
  State<_CopyableOrderId> createState() => _CopyableOrderIdState();
}

class _CopyableOrderIdState extends State<_CopyableOrderId> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.orderId));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _copied ? Icons.check_circle : Icons.copy_rounded,
            size: context.getScreenWidth(4),
            color: _copied ? Colors.green : AppColors.textMuted,
          ),
          SizedBox(width: context.getScreenWidth(1.5)),
          SizedBox(
            width: context.getScreenWidth(35),
            child: Text(
              '#${widget.orderId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.8),
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
      (Icons.verified_outlined, 'Booking verification',
          'We confirm stock availability and pricing'),
      (Icons.store_outlined, 'Visit Showroom',
          'Visit our showroom to complete your purchase'),
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
