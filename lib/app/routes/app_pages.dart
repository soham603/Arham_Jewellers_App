import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/controllers/navigation_controller.dart';
import '../../presentation/controllers/userOrderController.dart';
import '../../presentation/controllers/admin/AdminOrderController.dart';
import '../../presentation/pages/admin/handsetChangeScreen.dart';
import '../../presentation/pages/admin/orderDetailScreen.dart';
import '../../presentation/pages/admin/adminCustomOrderDetailPage.dart';
import '../../presentation/pages/admin/approveOrders.dart';
import '../../presentation/pages/auth/change_handset_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/checkout/checkout_page.dart';
import '../../presentation/pages/main_shell_view.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/orders/customOrderSuccessPage.dart';
import '../../presentation/pages/orders/my_orders_page.dart';
import '../../presentation/pages/orders/order_success_page.dart';
import '../../presentation/pages/orders/userOrderDetailScreen.dart';
import '../../presentation/pages/product/product_details_page.dart';
import '../../presentation/pages/ancillary/ancillary_page_screen.dart';
import '../../presentation/pages/share/share_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/wishlist/wishlist_page.dart';
import '../../presentation/pages/profile/goldRateDetailScreen.dart';
import 'app_routes.dart';
import '../../utils/Logger.dart';
import '../../utils/ToastUtil.dart';

class _MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
  }
}

abstract class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: SplashPage.new),
    GetPage(name: AppRoutes.login, page: LoginPage.new),
    GetPage(
      name: AppRoutes.home,
      page: MainShellView.new,
      transition: Transition.noTransition,
      binding: _MainShellBinding(),
    ),
    GetPage(name: AppRoutes.details, page: () => ProductDetailsPage(product: Get.arguments)),
    GetPage(name: AppRoutes.checkout, page: CheckoutPage.new),
    GetPage(name: AppRoutes.orderSuccess, page: OrderSuccessPage.new),
    GetPage(name: AppRoutes.myOrders, page: MyOrdersPage.new),
    GetPage(name: AppRoutes.register, page: RegisterPage.new),
    GetPage(name: AppRoutes.notifications, page: NotificationsPage.new),
    GetPage(name: AppRoutes.changeHandset, page: ChangeHandsetPage.new),
    GetPage(name: AppRoutes.forgotPassword, page: ForgotPasswordPage.new),
    GetPage(name: AppRoutes.handsetRequests, page: HandsetChangeScreen.new),
    GetPage(name: AppRoutes.share, page: SharePage.new),
    GetPage(name: AppRoutes.ancillary, page: AncillaryPageScreen.new),
    GetPage(name: AppRoutes.wishlist, page: WishlistPage.new),
    GetPage(name: AppRoutes.customOrderSuccess, page: CustomOrderSuccessPage.new),
    GetPage(name: AppRoutes.userOrderDetail, page: _resolveUserOrderDetail),
    GetPage(name: AppRoutes.adminOrderDetail, page: _resolveAdminOrderDetail),
    GetPage(name: AppRoutes.goldRateDetail, page: GoldRateDetailScreen.new),
  ];
}

Widget _resolveUserOrderDetail() {
  final orderId = (Get.arguments?['orderId'] ?? Get.arguments?['id'])?.toString();
  if (orderId != null && Get.isRegistered<UserOrderController>()) {
    final controller = Get.find<UserOrderController>();
    final order = controller.userOrders.cast<dynamic>().firstWhere(
      (o) => o.id?.toString() == orderId,
      orElse: () => null,
    );
    if (order != null) {
      return UserOrderDetailScreen(order: order);
    }
  }
  if (orderId == null) {
    Logger.warning('AppPages', 'userOrderDetail requested without orderId');
  } else if (!Get.isRegistered<UserOrderController>()) {
    Logger.warning(
      'AppPages',
      'userOrderDetail requested but UserOrderController is not registered',
    );
  } else {
    Logger.warning('AppPages', 'userOrderDetail: order $orderId not in cache');
  }
  ToastUtils.showError('Order not found');
  return MyOrdersPage();
}

Widget _resolveAdminOrderDetail() {
  final orderId = (Get.arguments?['orderId'] ?? Get.arguments?['id'])?.toString();
  if (orderId != null && Get.isRegistered<AdminOrderController>()) {
    final controller = Get.find<AdminOrderController>();
    final order = controller.orders.cast<dynamic>().firstWhere(
      (o) => o.id?.toString() == orderId,
      orElse: () => null,
    );
    if (order != null) {
      if (order.isCustom == true) {
        return AdminCustomOrderDetailPage(order: order);
      } else {
        return OrderDetailScreen(order: order);
      }
    }
  }
  if (orderId == null) {
    Logger.warning('AppPages', 'adminOrderDetail requested without orderId');
  } else if (!Get.isRegistered<AdminOrderController>()) {
    Logger.warning(
      'AppPages',
      'adminOrderDetail requested but AdminOrderController is not registered',
    );
  } else {
    Logger.warning('AppPages', 'adminOrderDetail: order $orderId not in cache');
  }
  ToastUtils.showError('Order not found');
  return ApproveOrdersScreen();
}
