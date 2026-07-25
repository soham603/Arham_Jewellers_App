import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';

class AdminConstants {
  /// Sync getter — returns the cached phone (may be fallback on cold start).
  static String get adminPhone {
    if (!Get.isRegistered<AncillaryController>()) return AncillaryController.fallbackPhone;
    return AncillaryController.instance.adminPhone.value;
  }

  /// Async getter — awaits the initial ADMIN_CONTACT fetch, then returns
  /// the real phone number. Use in tap/async handlers to avoid the
  /// cold-start race where the fetch hasn't completed yet.
  static Future<String> get adminPhoneAsync async {
    if (!Get.isRegistered<AncillaryController>()) return AncillaryController.fallbackPhone;
    return AncillaryController.instance.adminPhoneAsync;
  }
}
