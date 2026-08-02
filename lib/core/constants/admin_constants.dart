import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';

class AdminConstants {
  static String get adminPhone {
    if (!Get.isRegistered<AncillaryController>()) return AncillaryController.fallbackPhone;
    return AncillaryController.instance.adminPhone.value;
  }

  static Future<String> get adminPhoneAsync async {
    if (!Get.isRegistered<AncillaryController>()) return AncillaryController.fallbackPhone;
    return AncillaryController.instance.adminPhoneAsync;
  }
}
