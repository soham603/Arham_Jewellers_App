import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:get/get.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/wishlist_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes/app_pages.dart';
import '../core/theme/app_theme.dart';

class RatneshGoldApp extends StatefulWidget {
  const RatneshGoldApp({super.key});

  static const String screenshotProtectionKey = 'screenshot_protection_enabled';
  static const String screenshotProtectionExpiryKey = 'screenshot_protection_expiry';

  static Future<bool> isScreenshotProtectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(screenshotProtectionKey) ?? true;
  }

  static Future<void> setScreenshotProtectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(screenshotProtectionKey, enabled);
    if (enabled) {
      await prefs.remove(screenshotProtectionExpiryKey);
      await NoScreenshot.instance.screenshotOff();
    } else {
      await NoScreenshot.instance.screenshotOn();
    }
  }

  static Future<void> setScreenshotProtectionDisabledWithDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setBool(screenshotProtectionKey, false);
    await prefs.setInt(screenshotProtectionExpiryKey, expiryTime);
    await NoScreenshot.instance.screenshotOn();
  }

  static Future<void> checkAndReenableScreenshotProtection() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(screenshotProtectionKey) ?? true;
    if (enabled) return;

    final expiryTimestamp = prefs.getInt(screenshotProtectionExpiryKey);
    if (expiryTimestamp == null) return;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    if (DateTime.now().isAfter(expiryTime)) {
      await setScreenshotProtectionEnabled(true);
    }
  }

  @override
  State<RatneshGoldApp> createState() => _RatneshGoldAppState();
}

class _RatneshGoldAppState extends State<RatneshGoldApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScreenshotProtection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // AppLifecycleState.detached is only emitted when the engine itself is
    // being torn down (rare on iOS/Android where the OS typically kills the
    // process without emitting this event). This is a best-effort cleanup
    // path for desktop/web/engine-shutdown scenarios.
    if (state == AppLifecycleState.detached) {
      _disposeGlobalControllers();
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    painting.ImageCache().clear();
  }

  Future<void> _initScreenshotProtection() async {
    await RatneshGoldApp.checkAndReenableScreenshotProtection();
    final enabled = await RatneshGoldApp.isScreenshotProtectionEnabled();
    if (enabled) {
      await NoScreenshot.instance.screenshotOff();
    } else {
      await NoScreenshot.instance.screenshotOn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          SafeArea(
            child: GetMaterialApp(
              title: 'Ratnesh Gold',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme,
              initialRoute: AppPages.initial,
              getPages: AppPages.routes,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: IgnorePointer(
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disposes all globally-registered GetX controllers. Each disposal is
/// wrapped independently so a single failure does not prevent the rest from
/// being cleaned up. `force: true` is required to dispose controllers that
/// were registered with `permanent: true` — without it, GetX logs a warning
/// and skips the deletion.
void _disposeGlobalControllers() {
  void safeDispose<T extends GetxController>() {
    try {
      if (Get.isRegistered<T>()) Get.delete<T>(force: true);
    } catch (e) {
    }
  }

  safeDispose<CartController>();
  safeDispose<WishlistController>();
  safeDispose<AuthController>();
  safeDispose<GoldRateController>();
  safeDispose<NotificationController>();
  safeDispose<CategoryController>();
  safeDispose<CarouselsController>();
  safeDispose<UserOrderController>();
  safeDispose<AncillaryController>();
}
