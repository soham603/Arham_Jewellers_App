import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../controllers/navigation_controller.dart';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        controller.handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Obx(
            () => IndexedStack(
              index: controller.selectedIndex.value,
              children: _pages,
            ),
          ),
        ),
        bottomNavigationBar: Obx(
          () => AppBottomNav(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.switchTab,
          ),
        ),
      ),
    );
  }
}
