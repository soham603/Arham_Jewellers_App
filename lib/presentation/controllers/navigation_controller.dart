import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/category_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';


class NavigationController extends GetxController {
  final selectedIndex = 0.obs;

  late final PageController pageController;

  static const int homeIndex = 0;
  static const int searchIndex = 1;
  static const int collectionsIndex = 2;
  static const int cartIndex = 3;
  static const int profileIndex = 4;

  DateTime? _lastBackPress;

  bool _isAnimatingToPage = false;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void switchTab(int index) {
    if (index == collectionsIndex) {
      Get.to(() => CategoryListingPage(
            karats: [Karat.k18, Karat.k20, Karat.k22],
            title: 'Collections',
            showBothLogos: true,
          ));
      return;
    }
    final pageIndex = index > collectionsIndex ? index - 1 : index;
    if (pageIndex == selectedIndex.value) return;
    selectedIndex.value = pageIndex;
    _isAnimatingToPage = true;
    pageController.jumpToPage(pageIndex);
    _isAnimatingToPage = false;
  }

  void onPageChanged(int index) {
    if (_isAnimatingToPage) return;
    selectedIndex.value = index;
  }

  void handleBack() {
    if (selectedIndex.value != 0) {
      selectedIndex.value = 0;
      _isAnimatingToPage = true;
      pageController.jumpToPage(0);
      _isAnimatingToPage = false;
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      if (!kIsWeb) SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      HapticFeedback.lightImpact();
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    }
  }
}
