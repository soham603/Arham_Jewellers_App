import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
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
import 'package:ratnesh_gold_app/core/widgets/status_border_card.dart';
import 'package:ratnesh_gold_app/utils/whatsapp_util.dart';

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
    // AdminOrderController is registered as permanent by AdminPanelScreen.
    controller = Get.isRegistered<AdminOrderController>()
        ? Get.find<AdminOrderController>()
        : Get.put(AdminOrderController(), permanent: true);
    controller.fetchProductDetails(widget.order.orderItems);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final hasBottomActions = order.status == "PENDING" || order.status == "APPROVED";

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
            fontSize: context.getResponsiveSize(5),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.getResponsiveSize(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(context, order),
                  SizedBox(height: context.heightPercent(2)),
                  _buildOrderItems(context, order),
                  SizedBox(height: context.heightPercent(2)),
                  _buildTotalAmount(context, order),
                  SizedBox(height: context.heightPercent(2)),
                  _buildUserDetails(context, order),
                  if (order.adminMessage != null &&
                      order.adminMessage!.isNotEmpty) ...[
                    SizedBox(height: context.heightPercent(2)),
                    _buildAdminMessage(context, order),
                  ],
                ],
              ),
            ),
          ),
          if (hasBottomActions)
            Container(
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(4),
                context.heightPercent(1.5),
                context.getResponsiveSize(4),
                context.heightPercent(2),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (order.status == "PENDING") _buildActionButtons(context, order),
                  if (order.status == "APPROVED") _buildCompleteButton(context, order),
                  SizedBox(height: context.heightPercent(1.2)),
                  _buildWhatsAppButton(context, order),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, AdminOrderModel order) {
    final statusInfo = getStatusInfo(order.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                    fontSize: context.getResponsiveSize(5),
                  ),
                ),
              ),
              if (order.isCustom)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(2.5),
                    vertical: context.heightPercent(0.3),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "CUSTOM",
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w800,
                      fontSize: context.getResponsiveSize(2.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.heightPercent(1)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(2.5),
              vertical: context.heightPercent(0.3),
            ),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              order.status,
              style: TextStyle(
                color: statusInfo.color,
                fontWeight: FontWeight.w700,
                fontSize: context.getResponsiveSize(3),
              ),
            ),
          ),
          SizedBox(height: context.heightPercent(1.5)),
          _infoRow(
            context,
            icon: Icons.access_time_rounded,
            label: "Created",
            value: DateFormat("dd MMM yyyy • hh:mm a").format(order.createdAt.toLocal()),
          ),
          SizedBox(height: context.heightPercent(0.8)),
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
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              fontSize: context.getResponsiveSize(4.4),
            ),
          ),
          SizedBox(height: context.heightPercent(1.5)),
          ...List.generate(order.orderItems.length, (index) {
            final item = order.orderItems[index];
            final imageUrl = item.product.imageUrl;

            return Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(1.2)),
              child: Container(
                padding: EdgeInsets.all(context.getResponsiveSize(3)),
                decoration: BoxDecoration(
                  color: item.isRejected
                      ? Colors.red.withValues(alpha: 0.05)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isRejected
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: context.getResponsiveSize(14),
                        height: context.getResponsiveSize(14),
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
                    SizedBox(width: context.getResponsiveSize(3)),
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
                                    fontSize: context.getResponsiveSize(3.8),
                                  ),
                                ),
                              ),
                              if (item.isRejected)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.getResponsiveSize(1.5),
                                    vertical: context.heightPercent(0.2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    "REJECTED",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: context.getResponsiveSize(2.2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.heightPercent(0.5)),
                          Wrap(
                            spacing: context.getResponsiveSize(2),
                            runSpacing: context.heightPercent(0.6),
                            children: [
                              _itemDetailChip(
                                context,
                                label: "Qty: ${item.quantity}",
                              ),
                              if (item.price > 0)
                                _itemDetailChip(
                                  context,
                                  label: "₹${item.price.toStringAsFixed(2)}",
                                ),
                              ...() {
                                final chips = <Widget>[];
                                final isLoading = controller.isFetchingProductDetails;
                                final rawData = controller.getProductRawData(item.product.id);
                                final salesTouch = rawData?['SalesTouch']?.toString() ?? rawData?['Touch']?.toString();
                                if (salesTouch != null && salesTouch.isNotEmpty) {
                                  chips.add(_itemDetailChip(
                                    context,
                                    label: "Purity: $salesTouch",
                                  ));
                                }
                                final karigarNetWtVal = rawData != null ? double.tryParse(rawData['KarigarNetWt']?.toString() ?? '') : null;
                                final weight = karigarNetWtVal;
                                if (weight != null) {
                                  chips.add(_itemDetailChip(
                                    context,
                                    label: "Net Wt: ${weight.toStringAsFixed(2)}g",
                                  ));
                                }
                                final sizeVal = rawData?['Size1']?.toString();
                                if (sizeVal != null && sizeVal.isNotEmpty) {
                                  chips.add(_itemDetailChip(
                                    context,
                                    label: "Size: $sizeVal",
                                  ));
                                }
                                if (chips.isEmpty && isLoading) {
                                  chips.add(_ShimmerChip(context: context));
                                  chips.add(_ShimmerChip(context: context));
                                }
                                return chips;
                              }(),
                            ],
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
        horizontal: context.getResponsiveSize(2),
        vertical: context.heightPercent(0.2),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: context.getResponsiveSize(2.8),
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
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primaryGold,
              size: context.getResponsiveSize(5),
            ),
          ),
          SizedBox(width: context.getResponsiveSize(3)),
          Expanded(
            child: Text(
              "Total Amount",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(4),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            "₹${total.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.getResponsiveSize(5),
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
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              fontSize: context.getResponsiveSize(4.4),
            ),
          ),
          SizedBox(height: context.heightPercent(1.5)),
          _detailRow(
            context,
            icon: Icons.person_rounded,
            label: "Name",
            value: user.name,
          ),
          SizedBox(height: context.heightPercent(1)),
          _detailRow(
            context,
            icon: Icons.phone_rounded,
            label: "Phone",
            value: user.phoneNumber,
          ),
          if (user.companyName.isNotEmpty) ...[
            SizedBox(height: context.heightPercent(1)),
            _detailRow(
              context,
              icon: Icons.business_rounded,
              label: "Company",
              value: user.companyName,
            ),
          ],
          if (user.city.isNotEmpty) ...[
            SizedBox(height: context.heightPercent(1)),
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
        Icon(icon, size: context.getResponsiveSize(4.5), color: AppColors.textMuted),
        SizedBox(width: context.getResponsiveSize(2.5)),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: context.getResponsiveSize(2.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: context.getResponsiveSize(3.6),
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
        Icon(icon, size: context.getResponsiveSize(4), color: AppColors.textMuted),
        SizedBox(width: context.getResponsiveSize(2)),
        Text(
          "$label: ",
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: context.getResponsiveSize(3.2),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.getResponsiveSize(3.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMessage(BuildContext context, AdminOrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                size: context.getResponsiveSize(4.5),
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Text(
                order.status == "REJECTED" ? "Rejection Reason" : "Admin Message",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.getResponsiveSize(4.4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(1)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.getResponsiveSize(3)),
            decoration: BoxDecoration(
              color: order.status == "REJECTED"
                  ? Colors.red.withValues(alpha: 0.05)
                  : AppColors.primaryGold.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: order.status == "REJECTED"
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.primaryGold.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              order.adminMessage!,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.4),
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
              disabledBackgroundColor: Colors.green.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(1.5),
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
                      fontSize: context.getResponsiveSize(3.8),
                    ),
                  )),
          ),
        ),
        SizedBox(width: context.getResponsiveSize(3)),
        Expanded(
          child: ElevatedButton(
            onPressed: controller.isActionLoading
                ? null
                : () => _showRejectDialog(order),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(1.5),
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
                fontSize: context.getResponsiveSize(3.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton(BuildContext context, AdminOrderModel order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isActionLoading
            ? null
            : () => _showCompleteDialog(order),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF2D9D59),
          disabledBackgroundColor: const Color(0xFF2D9D59).withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(
            vertical: context.heightPercent(1.5),
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
                "Mark Completed",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: context.getResponsiveSize(3.8),
                ),
              )),
      ),
    );
  }

  void _showCompleteDialog(AdminOrderModel order) {
    final dateController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mark as Completed",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.8)),
                  Text(
                    "Order #${order.id.substring(0, 8)}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: context.getResponsiveSize(3.4),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                  Text(
                    "Delivery Date",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.3),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.8)),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
                          dateController.text = '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateController,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.6),
                        ),
                        decoration: InputDecoration(
                          hintText: "Select delivery date (optional)",
                          hintStyle: TextStyle(
                            fontSize: context.getResponsiveSize(3.4),
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                          contentPadding: EdgeInsets.all(context.getResponsiveSize(3)),
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
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                  Text(
                    "Completion Notes",
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.3),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.8)),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.6),
                    ),
                    decoration: InputDecoration(
                      hintText: "Optional notes",
                      hintStyle: TextStyle(
                        fontSize: context.getResponsiveSize(3.4),
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: EdgeInsets.all(context.getResponsiveSize(3)),
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
                  SizedBox(height: context.heightPercent(2)),
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
                              fontSize: context.getResponsiveSize(3.6),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.getResponsiveSize(3)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back();
                            await controller.performOrderAction(
                              orderId: order.id,
                              action: "COMPLETE",
                              allocations: [],
                              deliveryDate: selectedDate?.toIso8601String().split('T').first,
                              completeAdminNotes: notesController.text.trim(),
                            );
                            if (context.mounted) Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2D9D59),
                            padding: EdgeInsets.symmetric(
                              vertical: context.heightPercent(1.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Confirm Complete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.getResponsiveSize(3.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildWhatsAppButton(BuildContext context, AdminOrderModel order) {
    return GestureDetector(
      onTap: () async {
        final url = WhatsAppUtil.buildUrl(order.user.phoneNumber);
        await launchUrl(url);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: context.heightPercent(1.5),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F9EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              "Connect on WhatsApp",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
                fontSize: context.getResponsiveSize(3.8),
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
                  fontSize: context.getResponsiveSize(5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.heightPercent(0.8)),
              Text(
                "Order #${order.id.substring(0, 8)}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: context.getResponsiveSize(3.4),
                ),
              ),
              SizedBox(height: context.heightPercent(2)),
              TextField(
                controller: reasonController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.6),
                ),
                decoration: InputDecoration(
                  hintText: "Enter rejection reason",
                  hintStyle: TextStyle(
                    fontSize: context.getResponsiveSize(3.4),
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: EdgeInsets.all(context.getResponsiveSize(3)),
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
              SizedBox(height: context.heightPercent(2)),
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
                          fontSize: context.getResponsiveSize(3.6),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(3)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          ToastUtils.showWarning("Please enter rejection reason");
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
                          vertical: context.heightPercent(1.2),
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
                          fontSize: context.getResponsiveSize(3.6),
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

}

class _ShimmerChip extends StatelessWidget {
  final BuildContext context;
  const _ShimmerChip({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.getResponsiveSize(18),
      height: context.getResponsiveSize(5),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
