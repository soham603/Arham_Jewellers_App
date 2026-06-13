import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/adminProductController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveOrders.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/carouselManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/categoryManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/goldRateScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/productManagerScreen.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import 'ancillary_selection_screen.dart';

class StaffPanelScreen extends StatefulWidget {
  const StaffPanelScreen({super.key});

  @override
  State<StaffPanelScreen> createState() => _StaffPanelScreenState();
}

class _StaffPanelScreenState extends State<StaffPanelScreen> {
  bool _isGridView = true;

  late final AdminOrderController _adminOrderController;
  late final AdminProductController _adminProductController;
  late final AdminUserController _adminUserController;
  late final GoldRateController _goldRateController;

  @override
  void initState() {
    super.initState();
    _adminOrderController = Get.isRegistered<AdminOrderController>()
        ? Get.find<AdminOrderController>()
        : Get.put(AdminOrderController());
    _adminProductController = Get.isRegistered<AdminProductController>()
        ? Get.find<AdminProductController>()
        : Get.put(AdminProductController());
    _adminUserController = Get.isRegistered<AdminUserController>()
        ? Get.find<AdminUserController>()
        : Get.put(AdminUserController());
    _goldRateController = Get.isRegistered<GoldRateController>()
        ? Get.find<GoldRateController>()
        : Get.put(GoldRateController());
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.getScreenHeight(1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // STAFF HEADER CARD
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.getResponsiveSize(5)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF2E2E2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                      width: context.getResponsiveSize(18),
                      height: context.getResponsiveSize(18),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0D9488),
                      ),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: context.getResponsiveSize(10),
                      ),
                    ),
                    SizedBox(width: context.getResponsiveSize(4)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authController.user?.name ?? "Staff",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.getResponsiveSize(5.3),
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.5)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getResponsiveSize(3),
                              vertical: context.getScreenHeight(0.4),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              "Staff",
                              style: TextStyle(
                                color: const Color(0xFF5EEAD4),
                                fontWeight: FontWeight.w600,
                                fontSize: context.getResponsiveSize(3.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (authController.user != null) ...[
                  SizedBox(height: context.getScreenHeight(1.5)),
                  if (authController.user!.email.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.getScreenHeight(0.5)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            color: Colors.white60,
                            size: context.getResponsiveSize(3.8),
                          ),
                          SizedBox(width: context.getResponsiveSize(1.5)),
                          Expanded(
                            child: Text(
                              authController.user!.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: context.getResponsiveSize(3.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (authController.user!.phoneNumber.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.getScreenHeight(0.5)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            color: Colors.white60,
                            size: context.getResponsiveSize(3.8),
                          ),
                          SizedBox(width: context.getResponsiveSize(1.5)),
                          Expanded(
                            child: Text(
                              authController.user!.phoneNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: context.getResponsiveSize(3.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                SizedBox(height: context.getScreenHeight(2)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(4),
                    vertical: context.getScreenHeight(1.2),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        color: const Color(0xFF5EEAD4),
                        size: context.getResponsiveSize(5),
                      ),
                      SizedBox(width: context.getResponsiveSize(2)),
                      Expanded(
                        child: Text(
                          "Manage store operations and orders",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: context.getResponsiveSize(3.5),
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

          
          // QUICK STATS ROW
          
          _buildStatsRow(context),

          SizedBox(height: context.getScreenHeight(3)),

          
          // STAFF MENU GRID / LIST
          
          Row(
            children: [
              Text(
                "Management",
                style: TextStyle(
                  fontSize: context.getResponsiveSize(6),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isGridView = !_isGridView),
                child: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7DED2)),
                  ),
                  child: Icon(
                    _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                    color: AppColors.textMuted,
                    size: context.getResponsiveSize(5),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.getScreenHeight(2)),

          if (_isGridView)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: context.getResponsiveSize(3),
              mainAxisSpacing: context.getScreenHeight(1.5),
              childAspectRatio: 0.9,
              children: [
                _staffTile(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: "Approve Orders",
                  subtitle: "Verify orders",
                  onTap: () => Get.to(() => const ApproveOrdersScreen()),
                ),
                _staffTile(
                  context,
                  icon: Icons.production_quantity_limits_rounded,
                  title: "Products",
                  subtitle: "Manage products",
                  onTap: () => Get.to(() => AdminProductScreen()),
                ),
                _staffTile(
                  context,
                  icon: Icons.category_rounded,
                  title: "Categories",
                  subtitle: "Manage categories",
                  onTap: () => Get.to(() => CategoryManagerScreen()),
                ),
                _staffTile(
                  context,
                  icon: Icons.view_carousel_rounded,
                  title: "Carousel",
                  subtitle: "Manage banners",
                  onTap: () => Get.to(() => CarouselManagerScreen()),
                ),
                _staffTile(
                  context,
                  icon: Icons.monetization_on_rounded,
                  title: "Gold Rate",
                  subtitle: "Set daily rate",
                  onTap: () => Get.to(() => const GoldRateScreen()),
                ),
                _staffTile(
                  context,
                  icon: Icons.text_snippet_rounded,
                  title: "Ancillary Data",
                  subtitle: "Terms, About, Policies",
                  onTap: () => Get.to(() => const AncillarySelectionScreen()),
                ),
              ],
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _managementItems.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: context.getScreenHeight(1.2)),
              itemBuilder: (context, index) {
                final item = _managementItems[index];
                return _staffListTile(
                  context,
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: item.onTap,
                );
              },
            ),

          SizedBox(height: context.getScreenHeight(3)),
        ],
      ),
    );
  }

  List<_ManagementItem> get _managementItems => [
        _ManagementItem(Icons.inventory_2_rounded, "Approve Orders",
            "Verify orders", () => Get.to(() => const ApproveOrdersScreen())),
        _ManagementItem(Icons.production_quantity_limits_rounded, "Products",
            "Manage products", () => Get.to(() => AdminProductScreen())),
        _ManagementItem(Icons.category_rounded, "Categories",
            "Manage categories", () => Get.to(() => CategoryManagerScreen())),
        _ManagementItem(Icons.view_carousel_rounded, "Carousel",
            "Manage banners", () => Get.to(() => CarouselManagerScreen())),
        _ManagementItem(Icons.monetization_on_rounded, "Gold Rate",
            "Set daily rate", () => Get.to(() => const GoldRateScreen())),
        _ManagementItem(Icons.text_snippet_rounded, "Ancillary Data",
            "Terms, About, Policies",
            () => Get.to(() => const AncillarySelectionScreen())),
      ];

  Widget _buildStatsRow(BuildContext context) {
    final pendingOrdersCount = _adminOrderController.orders
        .where((o) => o.status.toUpperCase() == 'PENDING')
        .length;
    final totalProducts = _adminProductController.total;
    final pendingUsersCount = _adminUserController.total;
    final currentGoldRate = _goldRateController.currentRate?.rate;

    final stats = [
      _StatData(
        icon: Icons.inventory_2_rounded,
        label: 'Pending Orders',
        value: '$pendingOrdersCount',
        color: const Color(0xFFF59E0B),
      ),
      _StatData(
        icon: Icons.inventory_rounded,
        label: 'Total Products',
        value: '$totalProducts',
        color: const Color(0xFF3B82F6),
      ),
      _StatData(
        icon: Icons.people_rounded,
        label: 'Pending Users',
        value: '$pendingUsersCount',
        color: const Color(0xFF8B5CF6),
      ),
      _StatData(
        icon: Icons.monetization_on_rounded,
        label: 'Gold Rate',
        value: currentGoldRate != null
            ? '₹${currentGoldRate.toStringAsFixed(0)}'
            : '--',
        color: const Color(0xFFD4AF37),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
        final spacing = context.getResponsiveSize(2.5);
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: context.getScreenHeight(1),
          children: stats
              .map((s) => SizedBox(
                    width: itemWidth,
                    child: _statCard(
                      context,
                      icon: s.icon,
                      label: s.label,
                      value: s.value,
                      color: s.color,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(context.getResponsiveSize(3)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: context.getResponsiveSize(5),
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(width: context.getResponsiveSize(1.5)),
              Icon(
                icon,
                color: color,
                size: context.getResponsiveSize(3.5),
              ),
            ],
          ),
          SizedBox(height: context.getScreenHeight(0.3)),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: context.getResponsiveSize(2.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.getScreenHeight(1.5),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DED2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.getResponsiveSize(12),
              height: context.getResponsiveSize(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF5EFE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGold,
                size: context.getResponsiveSize(6),
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: context.getResponsiveSize(4),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: context.getResponsiveSize(3.2),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: context.getResponsiveSize(5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staffTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(4)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7DED2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.getResponsiveSize(14),
              height: context.getResponsiveSize(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF5EFE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGold,
                size: context.getResponsiveSize(7),
              ),
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontSize: context.getResponsiveSize(3.8),
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.4)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: context.getResponsiveSize(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementItem(this.icon, this.title, this.subtitle, this.onTap);
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
