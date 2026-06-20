import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:no_screenshot/no_screenshot.dart';
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

class _RatneshGoldAppState extends State<RatneshGoldApp> {
  @override
  void initState() {
    super.initState();
    _initScreenshotProtection();
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
