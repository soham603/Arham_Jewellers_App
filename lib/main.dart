import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/services/pdf_cache.dart';
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
import 'app/app.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      } catch (e, st) {
        debugPrint('Failed to lock orientation: $e\n$st');
      }

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      _registerControllers();
      painting.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

      runApp(RatneshGoldApp());

      if (!kIsWeb) {
        unawaited(
          NotificationService().init().timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('NotificationService.init timed out');
            },
          ),
        );
      }

      unawaited(
        PdfCache.clearStale().catchError((Object e, StackTrace st) {
          debugPrint('PdfCache.clearStale failed: $e\n$st');
        }),
      );
    },
    (error, stackTrace) {
      debugPrint('Unhandled zone error: $error\n$stackTrace');
    },
  );
}

void _registerControllers() {
  void safePut<T extends GetxController>(T controller, {bool permanent = false}) {
    try {
      Get.put(controller, permanent: permanent);
    } catch (e, st) {
      debugPrint('Failed to register ${controller.runtimeType}: $e\n$st');
    }
  }

  safePut(CartController());
  safePut(WishlistController());
  safePut(AuthController());
  safePut(GoldRateController());
  safePut(NotificationController());
  safePut(CategoryController(), permanent: true);
  safePut(CarouselsController(), permanent: true);
  safePut(UserOrderController(), permanent: true);
  safePut(AncillaryController(), permanent: true);
}
