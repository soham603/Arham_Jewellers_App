import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/responsive_wrapper.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/AuthController.dart';
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
        controller.handleBack();
      },
      child: Obx(() {
        final index = controller.selectedIndex.value;
        final isAdmin = authController.isAdmin;
        final pages = isAdmin ? _adminPages : _regularPages;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: ResponsiveWrapper(
              child: IndexedStack(
                index: index,
                children: pages,
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: index,
            onTap: controller.switchTab,
            isAdmin: isAdmin,
          ),
        );
      }),
    );
  }
}
