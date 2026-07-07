import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiUrlConstants {
  static String get BASE_URL => dotenv.env['BASE_URL'] ?? '';

  static const String USER_LOGIN = '/api/v1/auth/user-login';
  static const String ADMIN_LOGIN = '/api/v1/auth/admin-login';
  static const String REGISTER = '/api/v1/auth/register';
  static const String REFRESH_TOKEN = '/api/v1/auth/refresh-token';
  static const String FORGOT_PASSWORD = '/api/v1/auth/forgot-password';
  static const String UPDATE_FCM_TOKEN = '/api/v1/auth/update-fcm-token';
  static const String ADMIN_RESET_PASSWORD = '/api/v1/admin-access/admin-reset-password';
  static const String DEVICE_CHANGE_REQUEST = '/api/v1/auth/device-change-request';
  static const String DEVICE_CHANGE_REQUEST_ACTION = '/api/v1/auth/device-change-request/action';

  static const String PRODUCTS_GET_ALL = '/api/v1/products/get-all';
  static const String PRODUCTS_SEARCH = '/api/v1/products/search';
  static const String PRODUCTS_CREATE_ORDER = '/api/v1/products/create-order';
  static const String PRODUCTS_USER_ALL_ORDERS = '/api/v1/products/get-userAllOrders';
  static String productsUpdate(String id) => '/api/v1/products/update/$id';

  static const String CATEGORY_GET_ALL = '/api/v1/category/get-All';
  static const String CATEGORY_CREATE = '/api/v1/category/create';
  static String categoryEdit(String id) => '/api/v1/category/edit/$id';
  static String categoryDelete(String id) => '/api/v1/category/delete/$id';
  static String categoryRestore(String id) => '/api/v1/category/restore/$id';

  static const String CAROUSEL_GET_ALL = '/api/v1/carousel/get-All';
  static const String CAROUSEL_CREATE = '/api/v1/carousel/create';
  static String carouselEdit(String id) => '/api/v1/carousel/edit/$id';
  static String carouselDelete(String id) => '/api/v1/carousel/delete/$id';
  static String carouselRestore(String id) => '/api/v1/carousel/restore/$id';

  static const String LIVE_RATE_CURRENT = '/api/v1/live-rate/current';
  static const String LIVE_RATE_UPDATE = '/api/v1/live-rate/update';
  static const String LIVE_RATE_HISTORY = '/api/v1/live-rate/history';
  static const String LIVE_RATE_STATISTICS = '/api/v1/live-rate/statistics';

  static const String CUSTOM_ORDER_CREATE = '/api/v1/orders/custom-order';
  static String customOrderModify(String orderId) => '/api/v1/orders/custom-order/$orderId';
  static String customOrderDelete(String orderId) => '/api/v1/orders/custom-order/$orderId';

  static const String ADMIN_ORDER_GET_ALL = '/api/v1/admin-order/get-AllOrders';
  static const String ADMIN_ORDER_ACTION = '/api/v1/admin-order/order-action';
  static const String ADMIN_CUSTOM_ORDER_ACTION = '/api/v1/admin-order/custom-order/action';

  static const String ADMIN_ACCESS_GET_ALL = '/api/v1/admin-access/get-all-access';
  static const String ADMIN_ACCESS_HANDLE = '/api/v1/admin-access/handle-access';
  static const String ADMIN_ACCESS_GET_ALL_USERS = '/api/v1/admin-access/get-all-users';
  static const String CREATE_ADMIN = '/api/v1/admin-access/create-admin';
  static const String ADMIN_ACCESS_TOGGLE_RETAILER = '/api/v1/admin-access/toggle-retailer';
  static const String ADMIN_ACCESS_UPDATE_USER_ACTIVATION = '/api/v1/admin-access/update-user-activation';

  static String ancillaryGetPage(String page) => '/api/v1/ancillary/get-page/$page';
  static String ancillaryUpdatePage(String page) => '/api/v1/ancillary/update-page/$page';

  static const String CRAFTSMAN_GET_ALL = '/api/v1/craftsman/get-All';

  static const String NOTIFICATION_GET_ALL = '/api/v1/notifications/get-all';
  static const String NOTIFICATION_ACTION = '/api/v1/notifications/action';
  static const String NOTIFICATION_SEND = '/api/v1/notifications/send';
  static const String NOTIFICATION_HISTORY = '/api/v1/notifications/history';
}
