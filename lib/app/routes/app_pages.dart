import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/pages/profile/profileScreen.dart';

import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/cart/cart_page.dart';
import '../../presentation/pages/checkout/checkout_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/product/product_details_page.dart';
import '../../presentation/pages/rings/rings_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/wishlist/wishlist_page.dart';
import 'app_routes.dart';

abstract class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: SplashPage.new),
    GetPage(name: AppRoutes.login, page: LoginPage.new),
    GetPage(name: AppRoutes.home, page: HomePage.new),
    GetPage(name: AppRoutes.search, page: SearchPage.new),
    GetPage(name: AppRoutes.rings, page: RingsPage.new),
    GetPage(name: AppRoutes.details, page: () => ProductDetailsPage(product: Get.arguments)),
    GetPage(name: AppRoutes.wishlist, page: WishlistPage.new),
    GetPage(name: AppRoutes.cart, page: CartPage.new),
    GetPage(name: AppRoutes.checkout, page: CheckoutPage.new),
    GetPage(name: AppRoutes.profile, page: ProfileScreen.new),
  ];
}
