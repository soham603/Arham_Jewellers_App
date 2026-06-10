import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  /// Shows a success toast with an optional [title] and [duration].
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

  /// Shows an error toast with an optional [title] and [duration].
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

  /// Shows a warning toast with an optional [title] and [duration].
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

  /// Shows an info toast with an optional [title] and [duration].
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

  /// Dismisses any currently visible toast immediately.
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
    // Guard: require GetMaterialApp to be in the widget tree.
    if (!_isGetContextAvailable()) {
      debugPrint('[ToastUtils] GetMaterialApp context is not available.');
      return;
    }

    // Guard: message must not be blank.
    if (message.trim().isEmpty) {
      debugPrint('[ToastUtils] Attempted to show a toast with an empty message.');
      return;
    }

    // Dismiss any existing snackbar before showing a new one to
    // prevent stacking / overlap issues.
    dismiss();

    final config = _defaultConfigs[type]!;
    final resolvedTitle = title ?? config.title;
    final resolvedDuration = duration ?? config.duration;
    final resolvedPosition = position ?? config.position;

    Get.rawSnackbar(
      messageText: _buildContent(resolvedTitle, message, config.icon),
      snackPosition: resolvedPosition,
      backgroundColor: config.backgroundColor,
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      borderRadius: 12,
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

  static Widget _buildContent(String? title, String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                if (title != null) const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
              child: Icon(icon, color: Colors.white, size: 24),
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
    } catch (_) {
      return false;
    }
  }
}
