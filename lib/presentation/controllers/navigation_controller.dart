import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/category_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';

class NavigationController extends GetxController {
  final selectedIndex = 0.obs;

  static const int collectionsIndex = 2;

  DateTime? _lastBackPress;

  void switchTab(int index, {bool isAdmin = false}) {
    if (!isAdmin && index == collectionsIndex) {
      Get.to(() => CategoryListingPage(
            karats: [Karat.k18, Karat.k20, Karat.k22],
            title: 'Collections',
            showBothLogos: true,
          ));
      return;
    }
    final page_index = isAdmin ? index : (index > collectionsIndex ? index - 1 : index);
    if (page_index == selectedIndex.value) return;
    selectedIndex.value = page_index;
  }

  void handleBack() {
    if (selectedIndex.value != 0) {
      selectedIndex.value = 0;
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
