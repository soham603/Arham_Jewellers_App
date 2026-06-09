import 'package:get/get.dart';

import '../../presentation/controllers/navigation_controller.dart';
import '../../presentation/pages/admin/handsetChangeScreen.dart';
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
import '../../presentation/pages/product/product_details_page.dart';
import '../../presentation/pages/ancillary/ancillary_page_screen.dart';
import '../../presentation/pages/share/share_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/chat/chat_screen.dart';
import '../../presentation/pages/wishlist/wishlist_page.dart';
import 'app_routes.dart';

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
    GetPage(name: AppRoutes.chat, page: ChatScreen.new),
    GetPage(name: AppRoutes.wishlist, page: WishlistPage.new),
    GetPage(name: AppRoutes.customOrderSuccess, page: CustomOrderSuccessPage.new),
  ];
}
