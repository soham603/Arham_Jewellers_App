import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  final selectedIndex = 0.obs;

  DateTime? _lastBackPress;

  void switchTab(int index) {
    if (index == selectedIndex.value) return;
    selectedIndex.value = index;
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
