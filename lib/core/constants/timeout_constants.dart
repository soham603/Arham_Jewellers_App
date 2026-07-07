import 'package:dio/dio.dart';

class AppTimeouts {
  static const quickSend = Duration(seconds: 10);
  static const quickReceive = Duration(seconds: 10);
  static const normalSend = Duration(seconds: 15);
  static const normalReceive = Duration(seconds: 30);
  static const downloadSend = Duration(seconds: 15);
  static const downloadReceive = Duration(seconds: 60);

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
}
