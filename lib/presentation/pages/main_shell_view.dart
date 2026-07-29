import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../controllers/admin/GoldRateController.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/AuthController.dart';
import '../controllers/notification_controller.dart';
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

  static final _adminPages = <Widget>[
    const HomePage(),
    const SearchPage(),
    const SharePage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<GoldRateController>()) {
        Get.find<GoldRateController>().enableAutoFetchOnInit();
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().enableAutoFetchOnInit();
      }
    });
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
        final navIndex = index >= 2 ? index + 1 : index;
        return Scaffold(
          backgroundColor: Colors.white,
          extendBody: true,
          body: PageView(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: navIndex,
            onTap: (i) => controller.switchTab(i),
            isAdmin: isAdmin,
          ),
        );
      }),
    );
  }
}
