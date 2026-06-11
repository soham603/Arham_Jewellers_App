import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

enum ToastType { success, error, warning, info }

class ToastConfig {
  final Color backgroundColor;
  final IconData icon;
  final String? title;
  final Duration duration;
  final SnackPosition position;

  const ToastConfig({
    required this.backgroundColor,
    required this.icon,
    this.title,
    this.duration = const Duration(seconds: 3),
    this.position = SnackPosition.TOP,
  });
}

class ToastUtils {
  ToastUtils._();

  // ─── Default Configurations ───────────────────────────────────────────────

  static const Map<ToastType, ToastConfig> _defaultConfigs = {
    ToastType.success: ToastConfig(
      backgroundColor: Color(0xFF2E7D32),
      icon: Icons.check_circle_outline_rounded,
      title: 'Success',
    ),
    ToastType.error: ToastConfig(
      backgroundColor: Color(0xFFC62828),
      icon: Icons.error_outline_rounded,
      title: 'Error',
    ),
    ToastType.warning: ToastConfig(
      backgroundColor: Color(0xFFE65100),
      icon: Icons.warning_amber_rounded,
      title: 'Warning',
    ),
    ToastType.info: ToastConfig(
      backgroundColor: Color(0xFFA57A36),
      icon: Icons.info_outline_rounded,
      title: 'Info',
    ),
  };

  // ─── Public API ───────────────────────────────────────────────────────────

  static void showSuccess(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      type: ToastType.success,
      message: message,
      title: title,
      duration: duration,
      position: position,
    );
  }

  static void showError(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      type: ToastType.error,
      message: message,
      title: title,
      duration: duration,
      position: position,
    );
  }

  static void showWarning(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      type: ToastType.warning,
      message: message,
      title: title,
      duration: duration,
      position: position,
    );
  }

  static void showInfo(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      type: ToastType.info,
      message: message,
      title: title,
      duration: duration,
      position: position,
    );
  }

  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  // ─── Core ─────────────────────────────────────────────────────────────────

  static void _show({
    required ToastType type,
    required String message,
    String? title,
    Duration? duration,
    SnackPosition? position,
  }) {
    if (!_isGetContextAvailable()) {
      debugPrint('[ToastUtils] GetMaterialApp context is not available.');
      return;
    }

    if (message.trim().isEmpty) {
      debugPrint('[ToastUtils] Attempted to show a toast with an empty message.');
      return;
    }

    dismiss();

    final ctx = Get.context;
    if (ctx == null) return;
    final config = _defaultConfigs[type]!;
    final resolvedTitle = title ?? config.title;
    final resolvedDuration = duration ?? config.duration;
    final resolvedPosition = position ?? config.position;

    final margin = ctx.responsiveWidth(16, tabletVal: 32);
    final borderRadius = ctx.responsiveWidth(12, tabletVal: 20);

    Get.rawSnackbar(
      messageText: _buildContent(ctx, resolvedTitle, message, config.icon),
      snackPosition: resolvedPosition,
      backgroundColor: config.backgroundColor,
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      duration: resolvedDuration,
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  // ─── Widget Builders ──────────────────────────────────────────────────────

  static Widget _buildContent(BuildContext ctx, String? title, String message, IconData icon) {
    final hPad = ctx.responsiveWidth(16, tabletVal: 24);
    final vPad = ctx.responsiveWidth(12, tabletVal: 18);
    final iconLeft = ctx.responsiveWidth(36, tabletVal: 52);
    final iconSize = ctx.responsiveWidth(24, tabletVal: 36);
    final titleSize = ctx.responsiveFont(14);
    final messageSize = ctx.responsiveFont(13);
    final titleGap = ctx.responsiveWidth(2, tabletVal: 4);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(left: iconLeft),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                if (title != null) SizedBox(height: titleGap),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: messageSize,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static bool _isGetContextAvailable() {
    try {
      return Get.context != null;
    } catch (e, st) {
      Logger.error("ToastUtils", "Failed to check Get context availability", stackTrace: st);
      return false;
    }
  }
}
