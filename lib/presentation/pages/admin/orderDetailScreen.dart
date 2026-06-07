import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final AdminOrderModel order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final AdminOrderController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AdminOrderController>()) {
      controller = Get.find<AdminOrderController>();
    } else {
      controller = Get.put(AdminOrderController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Order Details",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getScreenWidth(5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.getScreenWidth(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(context, order),
            SizedBox(height: context.getScreenHeight(2)),
            _buildOrderItems(context, order),
            SizedBox(height: context.getScreenHeight(2)),
            _buildTotalAmount(context, order),
            SizedBox(height: context.getScreenHeight(2)),
            _buildUserDetails(context, order),
            if (order.adminMessage != null &&
                order.adminMessage!.isNotEmpty) ...[
              SizedBox(height: context.getScreenHeight(2)),
              _buildAdminMessage(context, order),
            ],
            SizedBox(height: context.getScreenHeight(2)),
            if (order.status == "PENDING") _buildActionButtons(context, order),
            SizedBox(height: context.getScreenHeight(1.5)),
            _buildWhatsAppButton(context, order),
            SizedBox(height: context.getScreenHeight(4)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, AdminOrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Order #${order.id.substring(0, 8)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.getScreenWidth(5),
                  ),
                ),
              ),
              if (order.isCustom)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(2.5),
                    vertical: context.getScreenHeight(0.3),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.primaryGold.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    "CUSTOM",
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w800,
                      fontSize: context.getScreenWidth(2.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.getScreenHeight(1)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.getScreenWidth(2.5),
              vertical: context.getScreenHeight(0.3),
            ),
            decoration: BoxDecoration(
              color: _orderStatusColor(order.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              order.status,
              style: TextStyle(
                color: _orderStatusColor(order.status),
                fontWeight: FontWeight.w700,
                fontSize: context.getScreenWidth(3),
              ),
            ),
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          _infoRow(
            context,
            icon: Icons.access_time_rounded,
            label: "Created",
            value: DateFormat("dd MMM yyyy • hh:mm a").format(order.createdAt.toLocal()),
          ),
          SizedBox(height: context.getScreenHeight(0.8)),
          _infoRow(
            context,
            icon: Icons.update_rounded,
            label: "Updated",
            value: DateFormat("dd MMM yyyy • hh:mm a").format(order.updatedAt.toLocal()),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, AdminOrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Items",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: context.getScreenWidth(4.4),
            ),
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          ...List.generate(order.orderItems.length, (index) {
            final item = order.orderItems[index];
            final imageUrl = controller.getProductImage(item.product.id);

            return Padding(
              padding: EdgeInsets.only(bottom: context.getScreenHeight(1.2)),
              child: Container(
                padding: EdgeInsets.all(context.getScreenWidth(3)),
                decoration: BoxDecoration(
                  color: item.isRejected
                      ? Colors.red.withOpacity(0.05)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isRejected
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: context.getScreenWidth(14),
                        height: context.getScreenWidth(14),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (_, _, _) =>
                                    const RatneshFallback.xs(),
                              )
                            : const RatneshFallback.xs(),
                      ),
                    ),
                    SizedBox(width: context.getScreenWidth(3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.getScreenWidth(3.8),
                                  ),
                                ),
                              ),
                              if (item.isRejected)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.getScreenWidth(1.5),
                                    vertical: context.getScreenHeight(0.2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    "REJECTED",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: context.getScreenWidth(2.2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.getScreenHeight(0.5)),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _itemDetailChip(
                                  context,
                                  label: "Qty: ${item.quantity}",
                                ),
                                if (item.price > 0) ...[
                                  SizedBox(width: context.getScreenWidth(2)),
                                  _itemDetailChip(
                                    context,
                                    label: "₹${item.price.toStringAsFixed(2)}",
                                  ),
                                ],
                                ...() {
                                  final chips = <Widget>[];
                                  final rawData = controller.getProductRawData(item.product.id);
                                  final netWtVal = rawData != null ? double.tryParse(rawData['NetWt']?.toString() ?? '') : null;
                                  final fineWtVal = rawData != null ? double.tryParse(rawData['FineWt']?.toString() ?? '') : null;
                                  final weight = netWtVal ?? fineWtVal;
                                  if (weight != null) {
                                    final isFallback = netWtVal == null;
                                    chips.add(SizedBox(width: context.getScreenWidth(2)));
                                    chips.add(_itemDetailChip(
                                      context,
                                      label: "${isFallback ? 'Fine' : 'Net'}: ${weight.toStringAsFixed(2)}g",
                                    ));
                                  }
                                  final sizeVal = rawData?['Size1']?.toString();
                                  if (sizeVal != null && sizeVal.isNotEmpty) {
                                    chips.add(SizedBox(width: context.getScreenWidth(2)));
                                    chips.add(_itemDetailChip(
                                      context,
                                      label: "Size: $sizeVal",
                                    ));
                                  }
                                  return chips;
                                }(),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _itemDetailChip(BuildContext context, {required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getScreenWidth(2),
        vertical: context.getScreenHeight(0.2),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: context.getScreenWidth(2.8),
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTotalAmount(BuildContext context, AdminOrderModel order) {
    final total = order.totalAmount;
    if (total == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.getScreenWidth(2.5)),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primaryGold,
              size: context.getScreenWidth(5),
            ),
          ),
          SizedBox(width: context.getScreenWidth(3)),
          Expanded(
            child: Text(
              "Total Amount",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getScreenWidth(4),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            "₹${total.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.getScreenWidth(5),
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context, AdminOrderModel order) {
    final user = order.user;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customer Details",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: context.getScreenWidth(4.4),
            ),
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          _detailRow(
            context,
            icon: Icons.person_rounded,
            label: "Name",
            value: user.name,
          ),
          SizedBox(height: context.getScreenHeight(1)),
          _detailRow(
            context,
            icon: Icons.phone_rounded,
            label: "Phone",
            value: user.phoneNumber,
          ),
          if (user.companyName.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(1)),
            _detailRow(
              context,
              icon: Icons.business_rounded,
              label: "Company",
              value: user.companyName,
            ),
          ],
          if (user.city.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(1)),
            _detailRow(
              context,
              icon: Icons.location_city_rounded,
              label: "City",
              value: user.city,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: context.getScreenWidth(4.5), color: AppColors.textMuted),
        SizedBox(width: context.getScreenWidth(2.5)),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: context.getScreenWidth(2.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: context.getScreenWidth(3.6),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: context.getScreenWidth(4), color: AppColors.textMuted),
        SizedBox(width: context.getScreenWidth(2)),
        Text(
          "$label: ",
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: context.getScreenWidth(3.2),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.getScreenWidth(3.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMessage(BuildContext context, AdminOrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: order.status == "REJECTED" ? Colors.red : AppColors.primaryGold,
                size: context.getScreenWidth(4.5),
              ),
              SizedBox(width: context.getScreenWidth(2)),
              Text(
                order.status == "REJECTED" ? "Rejection Reason" : "Admin Message",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.getScreenWidth(4.4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.getScreenHeight(1)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.getScreenWidth(3)),
            decoration: BoxDecoration(
              color: order.status == "REJECTED"
                  ? Colors.red.withOpacity(0.05)
                  : AppColors.primaryGold.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: order.status == "REJECTED"
                    ? Colors.red.withOpacity(0.15)
                    : AppColors.primaryGold.withOpacity(0.15),
              ),
            ),
            child: Text(
              order.adminMessage!,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.4),
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AdminOrderModel order) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.isActionLoading
                ? null
                : () async {
                    await controller.performOrderAction(
                      orderId: order.id,
                      action: "APPROVE",
                      allocations: order.orderItems.map((item) {
                        return {
                          "orderItemId": item.id,
                          "quantity": item.quantity,
                        };
                      }).toList(),
                    );
                    if (context.mounted) Get.back();
                  },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.green.withOpacity(0.5),
              padding: EdgeInsets.symmetric(
                vertical: context.getScreenHeight(1.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Obx(() => controller.isActionLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    "Approve",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.getScreenWidth(3.8),
                    ),
                  )),
          ),
        ),
        SizedBox(width: context.getScreenWidth(3)),
        Expanded(
          child: ElevatedButton(
            onPressed: controller.isActionLoading
                ? null
                : () => _showRejectDialog(order),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.red.withOpacity(0.5),
              padding: EdgeInsets.symmetric(
                vertical: context.getScreenHeight(1.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Reject",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.getScreenWidth(3.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppButton(BuildContext context, AdminOrderModel order) {
    return GestureDetector(
      onTap: () async {
        final url =
            "https://wa.me/${order.user.phoneNumber.replaceAll("+", "")}";
        await launchUrl(Uri.parse(url));
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: context.getScreenHeight(1.5),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F9EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
            SizedBox(width: context.getScreenWidth(2)),
            Text(
              "Connect on WhatsApp",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
                fontSize: context.getScreenWidth(3.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(AdminOrderModel order) {
    final reasonController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Reject Order",
                style: TextStyle(
                  fontSize: context.getScreenWidth(5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.getScreenHeight(0.8)),
              Text(
                "Order #${order.id.substring(0, 8)}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: context.getScreenWidth(3.4),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              TextField(
                controller: reasonController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.6),
                ),
                decoration: InputDecoration(
                  hintText: "Enter rejection reason",
                  hintStyle: TextStyle(
                    fontSize: context.getScreenWidth(3.4),
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: EdgeInsets.all(context.getScreenWidth(3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.6),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getScreenWidth(3)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          Get.snackbar(
                            "Required",
                            "Please enter rejection reason",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        Get.back();
                        await controller.performOrderAction(
                          orderId: order.id,
                          action: "REJECT",
                          allocations: [],
                          reason: reason,
                        );
                        if (context.mounted) Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          vertical: context.getScreenHeight(1.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: context.getScreenWidth(3.6),
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
      barrierDismissible: false,
    );
  }

  Color _orderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'CONFIRMED':
        return Colors.green;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      case 'PROCESSING':
        return const Color(0xFFA57A36);
      case 'COMPLETED':
      case 'DELIVERED':
        return const Color(0xFFD4AF37);
      default:
        return Colors.orange;
    }
  }
}
