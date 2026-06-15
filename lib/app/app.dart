import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:no_screenshot/secure_widget.dart';

import '../app/routes/app_pages.dart';
import '../core/theme/app_theme.dart';

class RatneshGoldApp extends StatelessWidget {
  const RatneshGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SecureWidget(
      child: GetMaterialApp(
        title: 'Ratnesh Gold',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}
