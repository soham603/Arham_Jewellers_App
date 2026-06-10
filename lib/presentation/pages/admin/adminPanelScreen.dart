import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveOrders.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveUsers.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/carouselManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/categoryManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/goldRateScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/handsetChangeScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/productManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/userManagementScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/splash/splash_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

// 🔥 Import the new Ancillary Data selection screen
import 'ancillary_selection_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

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
          // =====================================================
          // ADMIN HEADER CARD
          // =====================================================
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
                          SizedBox(height: context.getScreenHeight(0.5)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getResponsiveSize(3),
                              vertical: context.getScreenHeight(0.4),
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

          SizedBox(height: context.getScreenHeight(3)),

          // =====================================================
          // ADMIN MENU GRID
          // =====================================================
          Text(
            "Management",
            style: TextStyle(
              fontSize: context.getResponsiveSize(6),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),

          SizedBox(height: context.getScreenHeight(2)),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: context.gridColumns(),
            crossAxisSpacing: context.getResponsiveSize(3),
            mainAxisSpacing: context.getScreenHeight(1.5),
            childAspectRatio: 1.0,
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
                subtitle: "Manage products",
                onTap: () => Get.to(() => AdminProductScreen()),
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

              _adminTile(
                context,
                icon: Icons.play_circle_outline_rounded,
                title: "View Splash",
                subtitle: "Preview splash screen",
                onTap: () => Get.to(() => const SplashPage()),
              ),

              // ── Temporary: Toast Test ──
              _adminTile(
                context,
                icon: Icons.notifications_active_rounded,
                title: "Test Toast",
                subtitle: "Preview toasts",
                onTap: () => _showToastTestSheet(context),
              ),
            ],
          ),

          SizedBox(height: context.getScreenHeight(3)),
        ],
      ),
    );
  }

  void _showToastTestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(context.getResponsiveSize(5)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Test Toast",
              style: TextStyle(
                fontSize: context.getResponsiveSize(5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            _toastButton(
              context,
              label: "Success",
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.pop(ctx);
                ToastUtils.showSuccess("This is a success toast message.",
                    title: "Success");
              },
            ),
            SizedBox(height: context.getScreenHeight(1)),
            _toastButton(
              context,
              label: "Error",
              color: const Color(0xFFC62828),
              onTap: () {
                Navigator.pop(ctx);
                ToastUtils.showError("This is an error toast message.",
                    title: "Error");
              },
            ),
            SizedBox(height: context.getScreenHeight(1)),
            _toastButton(
              context,
              label: "Warning",
              color: const Color(0xFFE65100),
              onTap: () {
                Navigator.pop(ctx);
                ToastUtils.showWarning("This is a warning toast message.",
                    title: "Warning");
              },
            ),
            SizedBox(height: context.getScreenHeight(1)),
            _toastButton(
              context,
              label: "Info",
              color: const Color(0xFFA57A36),
              onTap: () {
                Navigator.pop(ctx);
                ToastUtils.showInfo("This is an info toast message.",
                    title: "Info");
              },
            ),
            SizedBox(height: context.getScreenHeight(2)),
          ],
        ),
      ),
    );
  }

  Widget _toastButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.getScreenHeight(1.2),
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: context.getResponsiveSize(4),
          ),
        ),
      ),
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