import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/adminPanelScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/ancillary/ancillary_page_screen.dart';
import 'package:ratnesh_gold_app/presentation/pages/orders/my_orders_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/orders/userOrderDetailScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/chat/chat_screen.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        // 🔥 The Nuclear Option to permanently remove the back arrow:
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        centerTitle: false, // 🔥 Forces title to the left
        titleSpacing: context.getScreenWidth(4),
        title: Text(
          isAdmin ? "Admin Panel" : "Profile",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getFontSize(5.5),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.getScreenWidth(2)),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: context.colorPalette.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: context.getScreenWidth(2)),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: context.getFontSize(4.5),
                            fontWeight: FontWeight.w700,
                            color: context.colorPalette.textColor,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(
                        fontSize: context.getFontSize(3.8),
                        color: context.colorPalette.subTitleColor,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: context.colorPalette.subTitleColor,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          if (isAdmin) {
                            await authController.logoutAdmin(context);
                          } else {
                            await authController.logoutUser(context);
                          }
                          Get.offAllNamed(AppRoutes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
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
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: context.getFontSize(6),
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
                      fontSize: context.getFontSize(4),
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
                                  size: context.getFontSize(10),
                                ),
                              ),

                              SizedBox(width: context.getScreenWidth(4)),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      authController.user?.name ?? "User",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: context.getFontSize(5.3),
                                      ),
                                    ),

                                    SizedBox(
                                      height: context.getScreenHeight(0.5),
                                    ),

                                    Text(
                                      "Premium Jewellery Customer",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: context.getFontSize(3.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: context.getScreenHeight(2.5)),

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
                                child: _profileStat(
                                  context,
                                  "Status",
                                  "Active",
                                ),
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
                                  size: context.getFontSize(5),
                                ),

                                SizedBox(width: context.getScreenWidth(2)),

                                Expanded(
                                  child: Text(
                                    "Trusted Jewellery Buyer",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.getFontSize(3.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (authController.user?.isRetailer == true) ...[
                            SizedBox(height: context.getScreenHeight(1)),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.getScreenWidth(4),
                                vertical: context.getScreenHeight(1.2),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.store_rounded,
                                    color: const Color(0xFFD4AF37),
                                    size: context.getFontSize(5),
                                  ),
                                  SizedBox(width: context.getScreenWidth(2)),
                                  Expanded(
                                    child: Text(
                                      "Retailer",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.getFontSize(3.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(3)),

                    Divider(color: Colors.grey.shade300),

                    SizedBox(height: context.getScreenHeight(2)),

                    // =====================================================
                    // TITLE
                    // =====================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "My Orders",
                          style: TextStyle(
                            fontSize: context.getFontSize(6),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.to(() => const MyOrdersPage()),
                          child: Text(
                            "View All",
                            style: TextStyle(
                              fontSize: context.getFontSize(4),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.getScreenHeight(2)),

                    // =====================================================
                    // ORDERS
                    // =====================================================
                    ...List.generate(orderController.userOrders.length, (
                      index,
                    ) {
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
                                      fontSize: context.getFontSize(4),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                    SizedBox(height: context.getScreenHeight(2)),

                    Divider(color: Colors.grey.shade300),

                    SizedBox(height: context.getScreenHeight(2)),

                    Text(
                      "Help & Info",
                      style: TextStyle(
                        fontSize: context.getFontSize(6),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(2)),

                    _chatButton(context),

                    SizedBox(height: context.getScreenHeight(2)),

                    _ancillaryLink(
                      context,
                      icon: Icons.description_rounded,
                      label: "Terms & Conditions",
                      pageKey: "TERMS",
                    ),
                    _ancillaryLink(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      label: "Privacy Policy",
                      pageKey: "PRIVACY",
                    ),
                    _ancillaryLink(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: "About Us",
                      pageKey: "ABOUT",
                    ),
                    _ancillaryLink(
                      context,
                      icon: Icons.replay_rounded,
                      label: "Refund Policy",
                      pageKey: "REFUND",
                    ),
                    _ancillaryLink(
                      context,
                      icon: Icons.location_city_rounded,
                      label: "City Policy",
                      pageKey: "CITY_POLICY",
                    ),
                    _ancillaryLink(
                      context,
                      icon: Icons.contact_mail_rounded,
                      label: "Contact Us",
                      pageKey: "CONTACT",
                    ),

                    SizedBox(height: context.getScreenHeight(3)),
                  ],
                ),
              );
            }),
    );
  }

  Widget _chatButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const ChatScreen()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(1.5),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF2E2E2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primaryGold,
                size: context.getFontSize(5),
              ),
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Shopping Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.getFontSize(4.2),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    'Browse jewellery, check rates, track orders',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: context.getFontSize(3),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.5),
              size: context.getFontSize(5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ancillaryLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String pageKey,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1)),
      child: GestureDetector(
        onTap: () => Get.to(() => const AncillaryPageScreen(), arguments: pageKey),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1.5),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryGold,
                size: context.getFontSize(5.5),
              ),
              SizedBox(width: context.getScreenWidth(3)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.getFontSize(4),
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: context.getFontSize(5),
              ),
            ],
          ),
        ),
      ),
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
              fontSize: context.getFontSize(5),
            ),
          ),

          SizedBox(height: context.getScreenHeight(0.4)),

          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: context.getFontSize(3.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.controller});

  final UserOrderModel order;
  final UserOrderController controller;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);

    return GestureDetector(
      onTap: () {
        Get.to(() => UserOrderDetailScreen(order: order));
      },
      child: Container(
        padding: EdgeInsets.all(context.getScreenWidth(4)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7DED2)),
        ),
        child: Row(
          children: [
            _OrderImagesStack(order: order, controller: controller),
            SizedBox(width: context.getScreenWidth(3)),
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
                      fontSize: context.getFontSize(4),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.4)),
                  Text(
                    DateFormat("dd MMM yyyy • hh:mm a").format(order.createdAt.toLocal()),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: context.getFontSize(3),
                    ),
                  ),
                ],
              ),
            ),
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
                  fontSize: context.getFontSize(2.8),
                ),
              ),
            ),
            SizedBox(width: context.getScreenWidth(2)),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: context.getFontSize(5),
            ),
          ],
        ),
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
          color: const Color(0xFFA57A36),
          bgColor: const Color(0xFFF9F3E8),
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
}

// ── Order Images Stack ───────────────────────────────────────────────────────

class _OrderImagesStack extends StatelessWidget {
  const _OrderImagesStack({required this.order, required this.controller});

  final UserOrderModel order;
  final UserOrderController controller;

  @override
  Widget build(BuildContext context) {
    final size = context.getScreenWidth(20);
    final items = order.items;
    final images = items
        .map((item) => item.product.imageUrl ?? controller.getProductImage(item.product.id))
        .where((url) => url != null && url.isNotEmpty)
        .toList();

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: RatneshFallback.s(width: size, height: size),
      );
    }

    final displayImages = images.take(3).toList();
    final totalItems = order.items.length;

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
                  child: _ProductImage(url: displayImages[i]),
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
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
