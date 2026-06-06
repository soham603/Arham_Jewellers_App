abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const search = '/search';
  static const details = '/details';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const profile = '/profile';
  static const orderSuccess = '/order-success';
  static const myOrders = '/my-orders';
  static const register = '/register';
  static const notifications = '/notifications';
  static const changeHandset = '/change-handset';
  static const handsetRequests = '/handset-requests';
  static const share = '/share';
  static const ancillary = '/ancillary';
  static const chat = '/chat';

  /// Tab index map for the main shell.
  static const int tabIndexHome = 0;
  static const int tabIndexSearch = 1;
  static const int tabIndexCart = 2;
  static const int tabIndexProfile = 3;

  // ── Custom Order ──
  static const customOrderDetail = '/custom-order-detail';
  static const customOrderSuccess = '/custom-order-success';
  static const adminCustomOrders = '/admin-custom-orders';
  static const adminCustomOrderDetail = '/admin-custom-order-detail';
}
