import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/craftsmanController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/orderDetailScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/adminCustomOrderDetailPage.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/widgets/adminOrderShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/core/widgets/status_border_card.dart';
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

    // AdminOrderController is registered as permanent by AdminPanelScreen
    // (and StaffPanelScreen as a fallback), so its fetched orders survive
    // route pops between admin order screens.
    controller = Get.isRegistered<AdminOrderController>()
        ? Get.find<AdminOrderController>()
        : Get.put(AdminOrderController(), permanent: true);

    // CraftsmanController is shared with AdminCustomOrderDetailPage.
    // Registered as permanent to keep the craftsman list cached across
    // navigation between admin order screens.
    if (!Get.isRegistered<CraftsmanController>()) {
      Get.put(CraftsmanController(), permanent: true);
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
            fontSize: context.getResponsiveSize(5),
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
                  size: context.getResponsiveSize(18),
                  color: Colors.red.shade300,
                ),
                SizedBox(height: context.heightPercent(1.5)),
                Text(
                  "Failed to load orders",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.getResponsiveSize(4.3),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.getResponsiveSize(4)),
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

              SizedBox(height: context.heightPercent(1.5)),

              // STATUS FILTER DROPDOWN
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(() {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(3),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE7DED2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedStatus.value,
                          isDense: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: context.getResponsiveSize(5)),
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.3),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                            DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                            DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                            DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                          ],
                          onChanged: (val) {
                            if (val != null) controller.changeStatus(val);
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),

              SizedBox(height: context.heightPercent(2)),

              if (controller.orders.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.heightPercent(12)),
                  child: Column(
                    children: [
                      Container(
                        width: context.getResponsiveSize(28),
                        height: context.getResponsiveSize(28),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6F7FB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: context.getResponsiveSize(12),
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(2)),
                      Text(
                        "No Orders Found",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.getResponsiveSize(5),
                        ),
                      ),
                      SizedBox(height: context.heightPercent(1)),
                      Text(
                        "No orders found for entered query",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: context.getResponsiveSize(3.5),
                        ),
                      ),
                    ],
                  ),
                ),

              if (controller.orders.isNotEmpty)
                ...List.generate(controller.orders.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: context.heightPercent(1.5),
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
                    top: context.heightPercent(1),
                    bottom: context.heightPercent(4),
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
                        horizontal: context.getResponsiveSize(9),
                        vertical: context.heightPercent(1.5),
                      ),
                    ),
                    child: Text(
                      "Load More",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: context.getResponsiveSize(3.8),
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
    final statusInfo = getStatusInfo(order.status);

    return GestureDetector(
      onTap: () {
        if (order.isCustom) {
          Get.to(() => AdminCustomOrderDetailPage(order: order));
        } else {
          Get.to(() => OrderDetailScreen(order: order));
        }
      },
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(4)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
            ),
            SizedBox(width: context.getResponsiveSize(4)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderTitle(order: order),
                  SizedBox(height: context.heightPercent(0.6)),
                  Text(
                    DateFormat("dd MMM yyyy • hh:mm a").format(order.createdAt.toLocal()),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: context.getResponsiveSize(3.4),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(1)),
                  Row(
                    children: [
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
                            fontSize: context.getResponsiveSize(2.8),
                          ),
                        ),
                      ),
                      if (order.isCustom) ...[
                        SizedBox(width: context.getResponsiveSize(1.5)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getResponsiveSize(2),
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
                              fontSize: context.getResponsiveSize(2.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.getResponsiveSize(3.5),
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTitle extends StatelessWidget {
  const _OrderTitle({required this.order});
  final AdminOrderModel order;

  @override
  Widget build(BuildContext context) {
    final title = _getTitle();
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: context.getResponsiveSize(4.4),
      ),
    );
  }

  String _getTitle() {
    if (order.partyName?.isNotEmpty == true) {
      return order.partyName!;
    }
    if (order.user.name.isNotEmpty) {
      return order.user.name;
    }
    if (order.user.companyName.isNotEmpty) {
      return order.user.companyName;
    }
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    return "Order #$shortId";
  }
}

class _OrderImagesStack extends StatelessWidget {
  const _OrderImagesStack({required this.order});

  final AdminOrderModel order;

  @override
  Widget build(BuildContext context) {
    final size = context.getResponsiveSize(20);

    final images = order.orderItems
        .map((item) => item.product.imageUrl)
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
                      color: Colors.black.withValues(alpha: 0.08),
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
                    fontSize: context.getResponsiveSize(3.2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

