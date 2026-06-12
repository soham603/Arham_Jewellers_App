import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/AuthController.dart';
import '../controllers/share_controller.dart';
import 'home/home_page.dart';
import 'search/search_page.dart';
import 'cart/cart_page.dart';
import 'profile/profileScreen.dart';
import 'share/share_page.dart';

class MainShellView extends GetView<NavigationController> {
  const MainShellView({super.key});

  static const _regularPages = <Widget>[
    HomePage(),
    SearchPage(),
    CartPage(),
    ProfileScreen(),
  ];

  static const _adminPages = <Widget>[
    HomePage(),
    SearchPage(),
    SharePage(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (Get.isRegistered<ShareController>()) {
          final shareCtrl = Get.find<ShareController>();
          if (shareCtrl.drillLevel == 3) {
            shareCtrl.goBackToLevel2();
            return;
          }
        }
        controller.handleBack();
      },
      child: Obx(() {
        final index = controller.selectedIndex.value;
        final isAdmin = authController.isAdmin;
        final pages = isAdmin ? _adminPages : _regularPages;
        final navIndex = isAdmin ? index : (index >= 2 ? index + 1 : index);
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: index,
                  children: pages,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(
                  currentIndex: navIndex,
                  onTap: (i) => controller.switchTab(i, isAdmin: isAdmin),
                  isAdmin: isAdmin,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
