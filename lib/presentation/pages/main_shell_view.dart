import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/AuthController.dart';
import 'home/home_page.dart';
import 'search/search_page.dart';
import 'cart/cart_page.dart';
import 'profile/profileScreen.dart';

class MainShellView extends GetView<NavigationController> {
  const MainShellView({super.key});

  static const _pages = <Widget>[
    HomePage(),
    SearchPage(),
    CartPage(),
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
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: index,
              children: _pages,
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
