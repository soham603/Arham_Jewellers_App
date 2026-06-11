import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

Future<String> getDeviceId() async {
  if (kIsWeb) {
    return 'web-${DateTime.now().millisecondsSinceEpoch}';
  }

  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? "unknown";
  }
}

Future<String> getDeviceName() async {
  if (kIsWeb) {
    return 'Web Browser';
  }

  final deviceInfo = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
  } catch (e, st) {
    Logger.error("DeviceIdService", "Failed to get device name", stackTrace: st);
    return 'Unknown Device';
  }
  return 'Unknown Device';
}
