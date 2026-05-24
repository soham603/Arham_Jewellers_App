import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/widgets/adminOrderShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:url_launcher/url_launcher.dart';

class ApproveOrdersScreen extends StatefulWidget {
  const ApproveOrdersScreen({super.key});

  @override
  State<ApproveOrdersScreen> createState() => _ApproveOrdersScreenState();
}

class _ApproveOrdersScreenState extends State<ApproveOrdersScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.pageBg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,

        title: Text(
          "Approve Orders",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getScreenWidth(5),
          ),
        ),
      ),

      body: Obx(() {
        final showInitialLoader =
            controller.orderState == CurrentAppState.LOADING &&
            controller.orders.isEmpty;

        if (showInitialLoader) {
          return const AdminOrderShimmer(showTopFilter: true);
        }

        if (controller.orderState == CurrentAppState.ERROR &&
            controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: context.getScreenWidth(18),
                  color: Colors.red.shade300,
                ),

                SizedBox(height: context.getScreenHeight(1.5)),

                Text(
                  "Failed to load orders",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.getScreenWidth(4.3),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.getScreenWidth(4)),

          child: Column(
            children: [
              // FILTER BAR
              Container(
                padding: EdgeInsets.all(context.getScreenWidth(3)),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: Colors.grey.shade200),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),

                      blurRadius: 12,
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    SizedBox(
                      width: context.getScreenWidth(30),

                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          value: controller.selectedStatus.value,

                          isExpanded: true,

                          decoration: _inputDecoration(context, "Status"),

                          items: ["PENDING", "APPROVED", "REJECTED"]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: context.getScreenWidth(3.3),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),

                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            controller.changeStatus(value);
                          },
                        ),
                      ),
                    ),

                    SizedBox(width: context.getScreenWidth(3)),

                    Expanded(
                      child: TextField(
                        controller: controller.searchController,

                        keyboardType: TextInputType.phone,

                        onChanged: controller.onSearchChanged,

                        decoration: _inputDecoration(
                          context,
                          "Search phone",
                          prefixIcon: Icons.search,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(2)),

              if (controller.orders.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.getScreenHeight(12)),

                  child: Column(
                    children: [
                      Container(
                        width: context.getScreenWidth(28),

                        height: context.getScreenWidth(28),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),

                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          Icons.shopping_bag_outlined,

                          size: context.getScreenWidth(12),

                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(2)),

                      Text(
                        "No Orders Found",

                        style: TextStyle(
                          fontWeight: FontWeight.w700,

                          fontSize: context.getScreenWidth(5),
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(1)),

                      Text(
                        "No orders found for entered query",

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Colors.grey.shade600,

                          fontSize: context.getScreenWidth(3.5),
                        ),
                      ),
                    ],
                  ),
                ),

              if (controller.orders.isNotEmpty)
                ...List.generate(controller.orders.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: context.getScreenHeight(1.5),
                    ),

                    child: _AdminOrderCard(
                      order: controller.orders[index],
                      controller: controller,
                    ),
                  );
                }),

              // PAGINATION SHIMMER
              if (controller.isPaginationLoading)
                const AdminOrderShimmer(showPagination: true)
              // LOAD MORE
              else if (controller.hasMore)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.getScreenHeight(1),

                    bottom: context.getScreenHeight(4),
                  ),

                  child: ElevatedButton(
                    onPressed: () {
                      controller.fetchOrders(isPagination: true);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),

                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(9),

                        vertical: context.getScreenHeight(1.5),
                      ),
                    ),

                    child: Text(
                      "Load More",

                      style: TextStyle(
                        color: Colors.white,

                        fontWeight: FontWeight.w700,

                        fontSize: context.getScreenWidth(3.8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint, {
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: hint == "Status" ? "Status" : null,
      hintText: hint == "Status" ? null : hint,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: Colors.grey.shade500),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.getScreenWidth(3.5),
        vertical: context.getScreenWidth(3.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
      ),
    );
  }
}

class _AdminOrderCard extends StatefulWidget {
  const _AdminOrderCard({required this.order, required this.controller});

  final AdminOrderModel order;
  final AdminOrderController controller;

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Container(
      padding: EdgeInsets.all(context.getScreenWidth(4)),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: context.getScreenWidth(20),
                height: context.getScreenWidth(20),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  color: const Color(0xFFFFF6EA),
                ),

                child: Icon(
                  Icons.shopping_bag_rounded,
                  color: AppColors.primaryGold,
                  size: context.getScreenWidth(9),
                ),
              ),

              SizedBox(width: context.getScreenWidth(4)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Order #${order.id.substring(0, 8)}",

                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.getScreenWidth(4.4),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(0.6)),

                    Text(
                      DateFormat(
                        "dd MMM yyyy • hh:mm a",
                      ).format(order.createdAt.toLocal()),

                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: context.getScreenWidth(3.4),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(1)),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(3),
                        vertical: context.getScreenHeight(0.5),
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),

                        borderRadius: BorderRadius.circular(100),
                      ),

                      child: Text(
                        order.status,

                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },

                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(2)),

                  GestureDetector(
                    onTap: () {
                      _showActionDialog(order);
                    },

                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(3),
                        vertical: context.getScreenHeight(0.7),
                      ),

                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (expanded) ...[
            SizedBox(height: context.getScreenHeight(2)),

            Divider(color: Colors.grey.shade300),

            SizedBox(height: context.getScreenHeight(1)),

            ...List.generate(order.orderItems.length, (index) {
              final item = order.orderItems[index];

              return Padding(
                padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),

                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        item.product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: context.getScreenWidth(3.8),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        "x${item.quantity}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }),

            Divider(color: Colors.grey.shade300),

            SizedBox(height: context.getScreenHeight(1)),

            Row(
              children: [
                const Icon(Icons.person),

                SizedBox(width: context.getScreenWidth(2)),

                Expanded(
                  child: Text(
                    order.user.name,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.getScreenHeight(1)),

            Row(
              children: [
                const Icon(Icons.phone),

                SizedBox(width: context.getScreenWidth(2)),

                Expanded(child: Text(order.user.phoneNumber)),
              ],
            ),

            SizedBox(height: context.getScreenHeight(2)),

            GestureDetector(
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
                    const Icon(Icons.whatshot, color: Colors.green),

                    SizedBox(width: context.getScreenWidth(2)),

                    Text(
                      "Connect on WhatsApp",

                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showActionDialog(AdminOrderModel order) {
    final reasonController = TextEditingController();
    final isRejecting = false.obs;

    Get.dialog(
      Obx(
        () => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 38,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Order Action",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  "Choose action for Order #${order.id.substring(0, 8)}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 24),

                if (widget.controller.isActionLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  if (isRejecting.value) ...[
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: "Enter rejection reason",
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await widget.controller.performOrderAction(
                              orderId: order.id,
                              action: "APPROVE",
                              allocations: order.orderItems.map((item) {
                                return {
                                  "orderItemId": item.id,
                                  "quantity": item.quantity,
                                };
                              }).toList(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Approve",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            isRejecting.value = true;
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Reject",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isRejecting.value) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
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

                          await widget.controller.performOrderAction(
                            orderId: order.id,
                            action: "REJECT",
                            allocations: [],
                            reason: reason,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Submit Reject Reason",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    reasonController.dispose();
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
