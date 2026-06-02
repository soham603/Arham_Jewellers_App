import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/adminPanelScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/widgets/adminDrawer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserOrderController orderController;
  late final AuthController authController;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  Worker? _adminWorker;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<UserOrderController>()) {
      orderController = Get.find<UserOrderController>();
    } else {
      orderController = Get.put(UserOrderController());
    }

    if (Get.isRegistered<AuthController>()) {
      authController = Get.find<AuthController>();
    } else {
      authController = Get.put(AuthController());
    }

    _adminWorker = ever(authController.isAdminRx, (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchUserOrders();
    });
  }

  @override
  void dispose() {
    _adminWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = authController.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      key: scaffoldKey,
      endDrawer: isAdmin ? const AdminDrawer() : null,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        title: Text(
          isAdmin ? "Admin Panel" : "Profile",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getScreenWidth(5.5),
          ),
        ),
        actions: [
          if (isAdmin)
            Padding(
              padding: EdgeInsets.only(right: context.getScreenWidth(2)),
              child: GestureDetector(
                onTap: () {
                  scaffoldKey.currentState?.openEndDrawer();
                },
                child: Container(
                  padding: EdgeInsets.all(context.getScreenWidth(2.5)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppColors.textDark,
                    size: context.getScreenWidth(6),
                  ),
                ),
              ),
            ),
        ],
      ),

      body: isAdmin
          ? const AdminPanelScreen()
          : Obx(() {
        if (orderController.ordersState == CurrentAppState.LOADING &&
            orderController.userOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderController.ordersState == CurrentAppState.ERROR &&
            orderController.userOrders.isEmpty) {
          return Center(
            child: Text(
              "Failed to load orders",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: context.getScreenWidth(4),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // PROFILE CARD
              // =====================================================
              Container(
                width: double.infinity,
                height: context.getScreenHeight(30),

                padding: EdgeInsets.all(context.getScreenWidth(5)),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF2E2E2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Container(
                          width: context.getScreenWidth(18),

                          height: context.getScreenWidth(18),

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),

                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: context.getScreenWidth(10),
                          ),
                        ),

                        SizedBox(width: context.getScreenWidth(4)),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                authController.user?.name ?? "User" ,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: context.getScreenWidth(5.3),
                                ),
                              ),

                              SizedBox(height: context.getScreenHeight(0.5)),

                              Text(
                                "Premium Jewellery Customer",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: context.getScreenWidth(3.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: _profileStat(
                            context,
                            "Orders",
                            "${orderController.totalOrders}",
                          ),
                        ),

                        SizedBox(width: context.getScreenWidth(3)),

                        Expanded(
                          child: _profileStat(context, "Status", "Active"),
                        ),
                      ],
                    ),

                    SizedBox(height: context.getScreenHeight(2)),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(4),
                        vertical: context.getScreenHeight(1.2),
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),

                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: context.getScreenWidth(5),
                          ),

                          SizedBox(width: context.getScreenWidth(2)),

                          Expanded(
                            child: Text(
                              "Trusted Jewellery Buyer",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.getScreenWidth(3.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(3)),

              Divider(color: Colors.grey.shade300),

              SizedBox(height: context.getScreenHeight(2)),

              // =====================================================
              // TITLE
              // =====================================================
              Text(
                "My Orders",
                style: TextStyle(
                  fontSize: context.getScreenWidth(6),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: context.getScreenHeight(2)),

              // =====================================================
              // ORDERS
              // =====================================================
              ...List.generate(orderController.userOrders.length, (index) {
                final order = orderController.userOrders[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: context.getScreenHeight(1.5),
                  ),

                  child: _OrderCard(
                    order: order,
                    controller: orderController,
                  ),
                );
              }),

              if (orderController.hasMoreOrders)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.getScreenHeight(1),
                    bottom: context.getScreenHeight(3),
                  ),

                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryGold,

                        padding: EdgeInsets.symmetric(
                          horizontal: context.getScreenWidth(8),
                          vertical: context.getScreenHeight(1.4),
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      onPressed: orderController.isFetchingOrders
                          ? null
                          : () {
                              orderController.loadMoreOrders();
                            },

                      child: orderController.isFetchingOrders
                          ? SizedBox(
                              width: context.getScreenWidth(4),
                              height: context.getScreenWidth(4),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Load More",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: context.getScreenWidth(4),
                              ),
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

  Widget _profileStat(BuildContext context, String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.4)),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.getScreenWidth(5),
            ),
          ),

          SizedBox(height: context.getScreenHeight(0.4)),

          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: context.getScreenWidth(3.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order, required this.controller});

  final UserOrderModel order;
  final UserOrderController controller;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool expanded = false;
  StreamSubscription? _imageSub;

  @override
  void initState() {
    super.initState();
    _imageSub = widget.controller.productImageCache.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusInfo = _getStatusInfo(order.status);

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
          GestureDetector(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderImagesStack(
                  order: order,
                  controller: widget.controller,
                ),
                SizedBox(width: context.getScreenWidth(4)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderToken != null
                            ? 'Order #${order.orderToken}'
                            : 'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.getScreenWidth(4.4),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(0.6)),
                      Text(
                        DateFormat("dd MMM yyyy • hh:mm a")
                            .format(order.createdAt.toLocal()),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: context.getScreenWidth(3.4),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(1)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getScreenWidth(2.5),
                          vertical: context.getScreenHeight(0.3),
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            color: statusInfo.color,
                            fontWeight: FontWeight.w700,
                            fontSize: context.getScreenWidth(2.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ],
            ),
          ),

          if (expanded) ...[
            SizedBox(height: context.getScreenHeight(2)),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: context.getScreenHeight(1)),

            ...List.generate(order.items.length, (index) {
              final item = order.items[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: context.getScreenHeight(1.5),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: context.getScreenWidth(12),
                        height: context.getScreenWidth(12),
                        child: _ProductImage(
                          url: widget.controller
                              .getProductImage(item.product.id),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.getScreenWidth(3.8),
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.3)),
                          Text(
                            "Qty: ${item.quantity}",
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: context.getScreenWidth(3.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${item.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                        fontSize: context.getScreenWidth(3.7),
                      ),
                    ),
                  ],
                ),
              );
            }),

            Divider(color: Colors.grey.shade300),
            SizedBox(height: context.getScreenHeight(1)),

            if (order.adminMessage != null &&
                order.adminMessage!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.getScreenWidth(3)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: context.getScreenWidth(4),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: context.getScreenWidth(2)),
                    Expanded(
                      child: Text(
                        order.adminMessage!,
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.4),
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.getScreenHeight(1.5)),
            ],

            if (order.totalAmount != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.8),
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(4.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.getScreenHeight(1.5)),
            ],

            GestureDetector(
              onTap: () async {
                final auth = Get.find<AuthController>();
                final phone = auth.user?.phoneNumber ?? "";
                final url = "https://wa.me/${phone.replaceAll("+", "")}";
                if (url != "https://wa.me/") {
                  await launchUrl(Uri.parse(url));
                }
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
                    const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.green,
                    ),
                    SizedBox(width: context.getScreenWidth(2)),
                    Text(
                      "Connect on WhatsApp",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: context.getScreenWidth(3.6),
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

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusInfo(
          label: 'Pending',
          color: Colors.orange,
          bgColor: const Color(0xFFFFF4E5),
        );
      case 'confirmed':
        return _StatusInfo(
          label: 'Confirmed',
          color: const Color(0xFF2D8C56),
          bgColor: const Color(0xFFE6F7EE),
        );
      case 'processing':
        return _StatusInfo(
          label: 'Processing',
          color: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
        );
      case 'completed':
      case 'delivered':
        return _StatusInfo(
          label: 'Delivered',
          color: AppColors.primaryGold,
          bgColor: const Color(0xFFF9F3E8),
        );
      case 'cancelled':
        return _StatusInfo(
          label: 'Cancelled',
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEE2E2),
        );
      case 'rejected':
        return _StatusInfo(
          label: 'Rejected',
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEE2E2),
        );
      default:
        return _StatusInfo(
          label: status.isNotEmpty
              ? '${status[0].toUpperCase()}${status.substring(1)}'
              : 'Unknown',
          color: AppColors.textMuted,
            bgColor: AppColors.tileBg,
        );
    }
  }

  @override
  void dispose() {
    _imageSub?.cancel();
    super.dispose();
  }
}

// ── Order Images Stack ───────────────────────────────────────────────────────

class _OrderImagesStack extends StatelessWidget {
  const _OrderImagesStack({
    required this.order,
    required this.controller,
  });

  final UserOrderModel order;
  final UserOrderController controller;

  @override
  Widget build(BuildContext context) {
    final size = context.getScreenWidth(20);
    final items = order.items;
    final images = items
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
    final extraCount = order.items.length - displayImages.length;

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
                  child: _ProductImage(url: displayImages[i]),
                ),
              ),
            ),
          if (extraCount > 0)
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
                  "+$extraCount",
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
}

// ── Product Image Widget ─────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, _) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, _, _) => const RatneshFallback.xs(),
      );
    }
    return const RatneshFallback.xs();
  }
}

// ── Status Info Model ────────────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.bgColor,
  });
}
