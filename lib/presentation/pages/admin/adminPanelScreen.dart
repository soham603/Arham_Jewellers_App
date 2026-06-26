import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserManagementController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/HandsetChangeController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveOrders.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveUsers.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/carouselManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/categoryManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/goldRateScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/handsetChangeScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/userManagementScreen.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/core/widgets/stat_card.dart';
import 'package:ratnesh_gold_app/app/app.dart';

import 'ancillary_selection_screen.dart';
import 'package:ratnesh_gold_app/presentation/pages/search/product_search_page.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isGridView = true;
  bool _screenshotProtectionEnabled = true;

  late final AdminOrderController _adminOrderController;
  late final AdminUserController _adminUserController;
  late final AdminUserManagementController _userManagementController;
  late final GoldRateController _goldRateController;
  late final HandsetChangeController _handsetChangeController;

  @override
  void initState() {
    super.initState();
    _loadScreenshotProtectionSetting();
    _adminOrderController = Get.isRegistered<AdminOrderController>()
        ? Get.find<AdminOrderController>()
        : Get.put(AdminOrderController());
    _adminUserController = Get.isRegistered<AdminUserController>()
        ? Get.find<AdminUserController>()
        : Get.put(AdminUserController());
    _userManagementController = Get.isRegistered<AdminUserManagementController>()
        ? Get.find<AdminUserManagementController>()
        : Get.put(AdminUserManagementController());
    _goldRateController = Get.isRegistered<GoldRateController>()
        ? Get.find<GoldRateController>()
        : Get.put(GoldRateController());
    _handsetChangeController = Get.isRegistered<HandsetChangeController>()
        ? Get.find<HandsetChangeController>()
        : Get.put(HandsetChangeController());
  }

  Future<void> _loadScreenshotProtectionSetting() async {
    final enabled = await RatneshGoldApp.isScreenshotProtectionEnabled();
    setState(() => _screenshotProtectionEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.heightPercent(1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // ADMIN HEADER CARD
          
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
                        color: AppColors.primaryGold,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
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
                            authController.user?.name ?? "Admin",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.getResponsiveSize(5.3),
                            ),
                          ),
                          SizedBox(height: context.heightPercent(0.5)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getResponsiveSize(3),
                              vertical: context.heightPercent(0.4),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              "Administrator",
                              style: TextStyle(
                                color: Colors.amber,
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
                SizedBox(height: context.heightPercent(2)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(4),
                    vertical: context.heightPercent(1.2),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: AppColors.primaryGold,
                        size: context.getResponsiveSize(5),
                      ),
                      SizedBox(width: context.getResponsiveSize(2)),
                      Expanded(
                        child: Text(
                          "Full access to manage app operations",
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

          SizedBox(height: context.heightPercent(3)),

          
          // ADMIN STATS GRID
          
          Obx(() => _buildStatsRow(context)),

          SizedBox(height: context.heightPercent(3)),

          
          // ADMIN MENU GRID / LIST
          
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

          SizedBox(height: context.heightPercent(2)),

          if (_isGridView)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: context.getResponsiveSize(3),
              mainAxisSpacing: context.heightPercent(1.5),
              childAspectRatio: 0.9,
              children: [
                _adminTile(
                  context,
                  icon: Icons.verified_user_rounded,
                  title: "Approve Users",
                  subtitle: "Manage access",
                  onTap: () => Get.to(() => const ApproveUsersScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: "User Management",
                  subtitle: "All users",
                  onTap: () => Get.to(() => const UserManagementScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: "Approve Orders",
                  subtitle: "Verify orders",
                  onTap: () => Get.to(() => const ApproveOrdersScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.category_rounded,
                  title: "Categories",
                  subtitle: "Manage categories",
                  onTap: () => Get.to(() => CategoryManagerScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.production_quantity_limits_rounded,
                  title: "Products",
                  subtitle: "Browse & edit products",
                  onTap: () => Get.to(() => const ProductSearchPage()),
                ),
                _adminTile(
                  context,
                  icon: Icons.view_carousel_rounded,
                  title: "Carousel",
                  subtitle: "Manage banners",
                  onTap: () => Get.to(() => CarouselManagerScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.text_snippet_rounded,
                  title: "Ancillary Data",
                  subtitle: "Terms, About, Policies",
                  onTap: () => Get.to(() => const AncillarySelectionScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.phone_android_rounded,
                  title: "Handset Requests",
                  subtitle: "Change requests",
                  onTap: () => Get.to(() => const HandsetChangeScreen()),
                ),
                _adminTile(
                  context,
                  icon: Icons.monetization_on_rounded,
                  title: "Gold Rate",
                  subtitle: "Set daily rate",
                  onTap: () => Get.to(() => const GoldRateScreen()),
                ),
                // ── Screenshot Protection Toggle ──
                _screenshotProtectionTile(context),
              ],
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _managementItems.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: context.heightPercent(1.2)),
              itemBuilder: (context, index) {
                final item = _managementItems[index];
                return _adminListTile(
                  context,
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: item.onTap,
                );
              },
            ),

          SizedBox(height: context.heightPercent(3)),
        ],
      ),
    );
  }

  List<_ManagementItem> get _managementItems => [
        _ManagementItem(Icons.verified_user_rounded, "Approve Users",
            "Manage access", () => Get.to(() => const ApproveUsersScreen())),
        _ManagementItem(Icons.people_alt_rounded, "User Management",
            "All users", () => Get.to(() => const UserManagementScreen())),
        _ManagementItem(Icons.inventory_2_rounded, "Approve Orders",
            "Verify orders", () => Get.to(() => const ApproveOrdersScreen())),
        _ManagementItem(Icons.category_rounded, "Categories",
            "Manage categories", () => Get.to(() => CategoryManagerScreen())),
        _ManagementItem(Icons.production_quantity_limits_rounded, "Products",
            "Browse & edit products", () => Get.to(() => const ProductSearchPage())),
        _ManagementItem(Icons.view_carousel_rounded, "Carousel",
            "Manage banners", () => Get.to(() => CarouselManagerScreen())),
        _ManagementItem(Icons.text_snippet_rounded, "Ancillary Data",
            "Terms, About, Policies",
            () => Get.to(() => const AncillarySelectionScreen())),
        _ManagementItem(Icons.phone_android_rounded, "Handset Requests",
            "Change requests", () => Get.to(() => const HandsetChangeScreen())),
        _ManagementItem(Icons.monetization_on_rounded, "Gold Rate",
            "Set daily rate", () => Get.to(() => const GoldRateScreen())),
      ];

  Widget _adminListTile(
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
          vertical: context.heightPercent(1.5),
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
                  SizedBox(height: context.heightPercent(0.3)),
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

  Widget _buildStatsRow(BuildContext context) {
    final pendingOrdersCount = _adminOrderController.orders
        .where((o) => o.status.toUpperCase() == 'PENDING')
        .length;
    final pendingUsersCount = _adminUserController.total;
    final currentGoldRate = _goldRateController.currentRate?.rate;
    final pendingHandsetCount = _handsetChangeController.total;
    final totalRetailers = _userManagementController.users
        .where((u) => u.isRetailer == true)
        .length;
    final pendingForgotPassword = _userManagementController.users
        .where((u) => u.forgotPasswordStatus != null &&
            u.forgotPasswordStatus!.toUpperCase() == 'PENDING')
        .length;

    final stats = [
      StatData(
        icon: Icons.inventory_2_rounded,
        label: 'Pending Orders',
        value: '$pendingOrdersCount',
        color: const Color(0xFFF59E0B),
      ),
      StatData(
        icon: Icons.people_rounded,
        label: 'Pending Users',
        value: '$pendingUsersCount',
        color: const Color(0xFF8B5CF6),
      ),
      StatData(
        icon: Icons.storefront_rounded,
        label: 'Total Retailers',
        value: '$totalRetailers',
        color: const Color(0xFF0D9488),
      ),
      StatData(
        icon: Icons.monetization_on_rounded,
        label: 'Gold Rate',
        value: currentGoldRate != null
            ? '₹${currentGoldRate.toStringAsFixed(0)}'
            : '--',
        color: const Color(0xFFD4AF37),
      ),
      StatData(
        icon: Icons.phone_android_rounded,
        label: 'Handset Requests',
        value: '$pendingHandsetCount',
        color: const Color(0xFF3B82F6),
      ),
      StatData(
        icon: Icons.lock_reset_rounded,
        label: 'Forgot Password',
        value: '$pendingForgotPassword',
        color: const Color(0xFFEF4444),
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
          runSpacing: context.heightPercent(1),
          children: stats
              .map((s) => SizedBox(
                    width: itemWidth,
                    child: StatCard(data: s),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _adminTile(
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
            SizedBox(height: context.heightPercent(1.5)),
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
            SizedBox(height: context.heightPercent(0.4)),
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

  Widget _screenshotProtectionTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_screenshotProtectionEnabled) {
          _showDisableDurationDialog(context);
        } else {
          _toggleScreenshotProtection(context, true);
        }
      },
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
                Icons.screenshot_rounded,
                color: _screenshotProtectionEnabled
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF2E7D32),
                size: context.getResponsiveSize(7),
              ),
            ),
            SizedBox(height: context.heightPercent(1.5)),
            Text(
              "Screenshot",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontSize: context.getResponsiveSize(3.8),
              ),
            ),
            SizedBox(height: context.heightPercent(0.4)),
            Switch(
              value: _screenshotProtectionEnabled,
              onChanged: (value) {
                if (!value) {
                  _showDisableDurationDialog(context);
                } else {
                  _toggleScreenshotProtection(context, true);
                }
              },
              activeThumbColor: const Color(0xFFEF4444),
              inactiveThumbColor: const Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleScreenshotProtection(BuildContext context, bool enable, {Duration? duration}) async {
    if (enable) {
      await RatneshGoldApp.setScreenshotProtectionEnabled(true);
    } else {
      await RatneshGoldApp.setScreenshotProtectionDisabledWithDuration(duration!);
    }
    setState(() => _screenshotProtectionEnabled = enable);
    ToastUtils.showSuccess(
      enable ? 'Screenshot protection enabled' : 'Screenshot protection disabled',
      title: 'Screenshot Setting',
    );
  }

  void _showDisableDurationDialog(BuildContext context) {
    int selectedHours = 0;
    int selectedMinutes = 30;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.colorPalette.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.screenshot_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  SizedBox(width: context.getResponsiveSize(2)),
                  Expanded(
                    child: Text(
                      'Disable Screenshot Protection',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(4.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For how long do you want to disable screenshot protection?',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hours',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.2),
                                fontWeight: FontWeight.w600,
                                color: context.colorPalette.subTitleColor,
                              ),
                            ),
                            SizedBox(height: context.heightPercent(0.5)),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE7DED2)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 22,
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B7355)),
                                      onPressed: selectedHours > 0
                                          ? () => setDialogState(() => selectedHours--)
                                          : null,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '$selectedHours',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(4.5),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 22,
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B7355)),
                                      onPressed: selectedHours < 23
                                          ? () => setDialogState(() => selectedHours++)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.widthPercent(3)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minutes',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.2),
                                fontWeight: FontWeight.w600,
                                color: context.colorPalette.subTitleColor,
                              ),
                            ),
                            SizedBox(height: context.heightPercent(0.5)),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE7DED2)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 22,
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B7355)),
                                      onPressed: selectedMinutes > 0
                                          ? () => setDialogState(() => selectedMinutes = (selectedMinutes - 5) % 60)
                                          : null,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '$selectedMinutes',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(4.5),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 22,
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B7355)),
                                      onPressed: selectedMinutes < 55
                                          ? () => setDialogState(() => selectedMinutes = (selectedMinutes + 5) % 60)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(1.5)),
                  Container(
                    padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: context.getResponsiveSize(2)),
                        Expanded(
                          child: Text(
                            'Protection will auto-enable after the selected duration',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3),
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor)),
                ),
                ElevatedButton(
                  onPressed: (selectedHours == 0 && selectedMinutes == 0)
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          final duration = Duration(hours: selectedHours, minutes: selectedMinutes);
                          _toggleScreenshotProtection(context, false, duration: duration);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Disable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
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

