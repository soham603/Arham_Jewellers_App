import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/routes/app_pages.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mobile_frame.dart';

class RatneshGoldApp extends StatelessWidget {
  const RatneshGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ratnesh Gold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      builder: (context, child) {
        // 🔥 The global SafeArea is removed here so the screen draws edge-to-edge
        return MobileFrame(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
