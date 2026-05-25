import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveOrders.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/approveUsers.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/carouselManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/categoryManagerScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/productManagerScreen.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer();

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: context.getScreenWidth(75),

      backgroundColor: const Color(0xFF1F1F1F),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(5),
            vertical: context.getScreenHeight(2),
          ),

          child: Column(
            children: [
              // ===================================================
              // HEADER
              // ===================================================
              Row(
                children: [
                  Container(
                    width: context.getScreenWidth(14),
                    height: context.getScreenWidth(14),

                    decoration: const BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: context.getScreenWidth(7),
                    ),
                  ),

                  SizedBox(width: context.getScreenWidth(3)),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Admin Panel",

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,

                            fontSize: context.getScreenWidth(5),
                          ),
                        ),

                        Text(
                          "Manage app operations",

                          style: TextStyle(
                            color: Colors.white70,

                            fontSize: context.getScreenWidth(3.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.getScreenHeight(3)),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),

                  child: Column(
                    children: [
                      _drawerItem(
                        context,
                        icon: Icons.verified_user_rounded,

                        title: "Approve Users",

                        subtitle: "Manage user approvals",

                        onTap: () {
                          Get.back();

                          Get.to(() => const ApproveUsersScreen());
                        },
                      ),

                      SizedBox(height: context.getScreenHeight(1.6)),

                      _drawerItem(
                        context,
                        icon: Icons.inventory_2_rounded,

                        title: "Approve Orders",

                        subtitle: "Verify jewellery orders",

                        onTap: () {
                          Get.back();

                          Get.to(() => const ApproveOrdersScreen());
                        },
                      ),

                      SizedBox(height: context.getScreenHeight(1.6)),

                      _drawerItem(
                        context,

                        icon: Icons.people_alt_rounded,

                        title: "Customers",

                        subtitle: "View all customers",

                        onTap: () {},
                      ),

                      SizedBox(height: context.getScreenHeight(1.6)),

                      _drawerItem(
                        context,

                        icon: Icons.settings_rounded,

                        title: "Category Manager",

                        subtitle: "Manage categories",

                        onTap: () {
                          Get.back();

                          Get.to(() => CategoryManagerScreen());
                        },
                      ),

                      SizedBox(height: context.getScreenHeight(1.6)),

                      _drawerItem(
                        context,

                        icon: Icons.production_quantity_limits_rounded,

                        title: "Product Manager",

                        subtitle: "Manage products",

                        onTap: () {
                          Get.back();

                          Get.to(() => AdminProductScreen());
                        },
                      ),

                      SizedBox(height: context.getScreenHeight(1.6)),

                      _drawerItem(
                        context,

                        icon: Icons.view_carousel_rounded,

                        title: "Carousel Manager",

                        subtitle: "Manage homepage banners",

                        onTap: () {
                          Get.back();
                          Get.to(() => CarouselManagerScreen());
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Column(
                children: [
                  const Divider(color: Colors.white24),

                  SizedBox(height: context.getScreenHeight(1)),

                  Align(
                    alignment: Alignment.bottomLeft,

                    child: _drawerItem(
                      context,

                      icon: Icons.logout_rounded,

                      title: "Logout",

                      subtitle: "Sign out from app",

                      iconColor: Colors.redAccent,

                      onTap: () {
                        final auth = Get.isRegistered<AuthController>()
                            ? Get.find<AuthController>()
                            : Get.put(AuthController());

                        Get.back();

                        auth.user?.role == 'ADMIN'
                            ? auth.logoutAdmin(context)
                            : auth.logoutUser(context);

                        Get.offAllNamed(AppRoutes.login);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        padding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(1.8),
        ),

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),

        child: Row(
          children: [
            Container(
              width: context.getScreenWidth(12),
              height: context.getScreenWidth(12),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Icon(
                icon,
                color: iconColor,
                size: context.getScreenWidth(6),
              ),
            ),

            SizedBox(width: context.getScreenWidth(4)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.getScreenWidth(4),
                    ),
                  ),

                  SizedBox(height: context.getScreenHeight(0.3)),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: context.getScreenWidth(3.2),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: context.getScreenWidth(4),
            ),
          ],
        ),
      ),
    );
  }
}
