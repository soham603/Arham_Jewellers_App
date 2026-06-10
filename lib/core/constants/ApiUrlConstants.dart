import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiUrlConstants {
  static String get BASE_URL => dotenv.env['BASE_URL'] ?? '';
  static const String UPDATE_FCM_TOKEN = '/api/v1/auth/update-fcm-token';
  static const String REFRESH_TOKEN = '/api/v1/auth/refresh-token';
  static const String FORGOT_PASSWORD = '/api/v1/auth/forgot-password';
  static const String ADMIN_RESET_PASSWORD = '/api/v1/auth/admin-reset-password';

  static const String LIVE_RATE_CURRENT = '/api/v1/live-rate/current';
  static const String LIVE_RATE_UPDATE = '/api/v1/live-rate/update';
  static const String LIVE_RATE_HISTORY = '/api/v1/live-rate/history';
  static const String LIVE_RATE_STATISTICS = '/api/v1/live-rate/statistics';

  static String ancillaryGetPage(String page) => '/api/v1/ancillary/get-page/$page';
  static String ancillaryUpdatePage(String page) => '/api/v1/ancillary/update-page/$page';

  // ── Custom Order ──
  static const String CUSTOM_ORDER_CREATE = '/api/v1/orders/custom-order';
  static String customOrderModify(String orderId) => '/api/v1/orders/custom-order/$orderId';
  static String customOrderDelete(String orderId) => '/api/v1/orders/custom-order/$orderId';

  // ── Admin Custom Order ──
  static const String ADMIN_CUSTOM_ORDER_ACTION = '/api/v1/admin-order/custom-order/action';

  // ── Craftsman ──
  static const String CRAFTSMAN_GET_ALL = '/api/v1/craftsman/get-All';
}
