import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/routes/app_pages.dart';
import '../core/theme/app_theme.dart';

class RatneshGoldApp extends StatelessWidget {
  const RatneshGoldApp({super.key});

  static bool _precacheDone = false;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ratnesh Gold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      builder: (context, child) {
        if (!_precacheDone) {
          _precacheDone = true;
          precacheImage(const AssetImage('assets/images/arham-logo.png'), context);
          precacheImage(const AssetImage('assets/images/ratnesh-logo.png'), context);
        }
        return child!;
      },
    );
  }
}
