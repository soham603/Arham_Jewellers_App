import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Colors.green,
      Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Colors.red,
      Icons.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Colors.orange,
      Icons.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Colors.blue,
      Icons.info,
    );
  }

  static void _showToast(
      BuildContext context, String message, Color color, IconData icon) {
    Flushbar(
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14.0),
      backgroundColor: color,
      flushbarPosition: FlushbarPosition.TOP,
      duration: const Duration(seconds: 5),
      icon: Icon(
        icon,
        color: context.colorPalette.backgroundColor,
        size: 24,
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: context.colorPalette.reverseTextColor,
          fontSize: context.getScreenWidth(3.25),
          fontWeight: FontWeight.w500,
        ),
      ),
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }
}
