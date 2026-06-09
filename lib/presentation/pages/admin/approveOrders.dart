import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/orderDetailScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/adminCustomOrderDetailPage.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/widgets/adminOrderShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

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
            fontSize: context.getFontSize(5),
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
                    fontSize: context.getFontSize(4.3),
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
              // SEARCH BAR
              SearchBarWidget(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                outerBackgroundColor: Colors.transparent,
                hintText: "Search phone",
                onClear: () {
                  controller.searchController.clear();
                  controller.onSearchChanged("");
                },
              ),

              SizedBox(height: context.getScreenHeight(1.5)),

              // STATUS FILTER
              Obx(
                () => Row(
                  children: [
                    _filterSegment(
                      context,
                      label: 'PENDING',
                      isActive: controller.selectedStatus.value == 'PENDING',
                      color: const Color(0xFFD4AF37),
                      onTap: () => controller.changeStatus('PENDING'),
                    ),
                    SizedBox(width: context.getScreenWidth(1)),
                    _filterSegment(
                      context,
                      label: 'APPROVED',
                      isActive: controller.selectedStatus.value == 'APPROVED',
                      color: Colors.green,
                      onTap: () => controller.changeStatus('APPROVED'),
                    ),
                    SizedBox(width: context.getScreenWidth(1)),
                    _filterSegment(
                      context,
                      label: 'REJECTED',
                      isActive: controller.selectedStatus.value == 'REJECTED',
                      color: Colors.red,
                      onTap: () => controller.changeStatus('REJECTED'),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6F7FB),
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
                          fontSize: context.getFontSize(5),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(1)),
                      Text(
                        "No orders found for entered query",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: context.getFontSize(3.5),
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
                        fontSize: context.getFontSize(3.8),
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
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.controller});

  final AdminOrderModel order;
  final AdminOrderController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (order.isCustom) {
          Get.to(() => AdminCustomOrderDetailPage(order: order));
        } else {
          Get.to(() => OrderDetailScreen(order: order));
        }
      },
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderImagesStack(
              order: order,
              controller: controller,
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
                      fontSize: context.getFontSize(4.4),
                    ),
                  ),
                  if (order.isCustom) ...[
                    SizedBox(height: context.getScreenHeight(0.4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(2),
                        vertical: context.getScreenHeight(0.2),
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
                          fontSize: context.getFontSize(2.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: context.getScreenHeight(0.6)),
                  Text(
                    DateFormat("dd MMM yyyy • hh:mm a").format(order.createdAt.toLocal()),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: context.getFontSize(3.4),
                    ),
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
                        fontSize: context.getFontSize(2.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.getScreenWidth(3.5),
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderImagesStack extends StatelessWidget {
  const _OrderImagesStack({
    required this.order,
    required this.controller,
  });

  final AdminOrderModel order;
  final AdminOrderController controller;

  @override
  Widget build(BuildContext context) {
    final size = context.getScreenWidth(20);

    return Obx(() {
      final images = order.orderItems
          .map((item) => controller.getProductImage(item.product.id))
          .where((url) => url != null && url.isNotEmpty)
          .toList();

      if (images.isEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: RatneshFallback.s(width: size, height: size),
        );
      }

      final displayImages = images.take(3).toList();
      final totalItems = order.orderItems.length;

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
                    borderRadius: BorderRadius.circular(14),
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
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: displayImages[i]!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: const Color(0xFFF6F7FB),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => RatneshFallback.s(),
                    ),
                  ),
                ),
              ),
            if (totalItems > 1)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    "$totalItems",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.getFontSize(3.2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
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

Widget _filterSegment(
  BuildContext context, {
  required String label,
  required bool isActive,
  required Color color,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: context.getScreenWidth(0.5)),
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.8)),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.getFontSize(3),
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  );
}
