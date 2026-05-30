import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiUrlConstants {
  static String get BASE_URL => dotenv.env['BASE_URL'] ?? '';
  static const String UPDATE_FCM_TOKEN = '/api/v1/auth/update-fcm-token';
  static const String REFRESH_TOKEN = '/api/v1/auth/refresh-token';
}
