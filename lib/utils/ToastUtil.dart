import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showToast(message, Colors.green, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _showToast(message, Colors.red, Icons.error);
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(message, Colors.orange, Icons.warning);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(message, const Color(0xFFA57A36), Icons.info);
  }

  static void _showToast(String message, Color color, IconData icon) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 5),
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      icon: Icon(icon, color: Colors.white, size: 24),
      colorText: Colors.white,
      titleText: const SizedBox.shrink(),
    );
  }
}
