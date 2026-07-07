import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
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

      Get.put(CartController());
      Get.put(WishlistController());
      Get.put(AuthController());
      Get.put(GoldRateController());
      Get.put(NotificationController());
      Get.put(CategoryController(), permanent: true);
      // Permanent: shared by HomePage and CarouselManagerScreen, and
      // referenced by _resolveUserOrderDetail in app_pages.dart.
      Get.put(CarouselsController(), permanent: true);
      Get.put(UserOrderController(), permanent: true);
      // Permanent: shared by AncillaryPageScreen (read) and
      // AncillaryEditorScreen (write) so fetched page content survives
      // navigation between the two.
      Get.put(AncillaryController(), permanent: true);

      if (!kIsWeb) {
        try {
          await NotificationService().init();
        } catch (e) {
          Logger.error('Main', 'NotificationService init failed: $e');
        }
      }

      painting.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

      runApp(RatneshGoldApp());
    },
    (error, stackTrace) {
      Logger.error('Uncaught Error', '$error\n$stackTrace');
    },
  );
}
