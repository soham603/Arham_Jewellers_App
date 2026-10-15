import 'package:dio/dio.dart';

class AppTimeouts {
  static const quickSend = Duration(seconds: 10);
  static const quickReceive = Duration(seconds: 10);
  static const normalSend = Duration(seconds: 15);
  static const normalReceive = Duration(seconds: 30);
  static const downloadSend = Duration(seconds: 15);
  static const downloadReceive = Duration(seconds: 60);

  static const uploadSend = Duration(minutes: 5);
  static const uploadReceive = Duration(minutes: 5);

  static const syncSend = Duration(seconds: 30);
  static const syncReceive = Duration(minutes: 20);

  static Options get quick => Options(
    sendTimeout: quickSend,
    receiveTimeout: quickReceive,
  );

  static Options get normal => Options(
    sendTimeout: normalSend,
    receiveTimeout: normalReceive,
  );

  static Options get download => Options(
    sendTimeout: downloadSend,
    receiveTimeout: downloadReceive,
    extra: {'requiresAuth': false},
  );

  static Options get sync => Options(
    sendTimeout: syncSend,
    receiveTimeout: syncReceive,
  );
}
