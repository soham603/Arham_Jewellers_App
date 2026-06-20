import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/wishlist_controller.dart';
import 'package:ratnesh_gold_app/services/notification_service.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'app/app.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Logger.error('FlutterError', details.exception.toString());
      };

      await dotenv.load();

      Get.put(CartController());
      Get.put(WishlistController());
      Get.put(AuthController());
      Get.put(GoldRateController());
      Get.put(NotificationController());

      if (!kIsWeb) {
        try {
          await NotificationService().init();
        } catch (e) {
          Logger.error('Main', 'NotificationService init failed: $e');
        }
      }

      runApp(RatneshGoldApp());
    },
    (error, stackTrace) {
      Logger.error('Uncaught Error', '$error\n$stackTrace');
    },
  );
}
