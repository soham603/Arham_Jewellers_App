import 'package:get/get.dart';

import '../../domain/entities/product.dart';

class WishlistController extends GetxController {
  final wishlist = <Product>[].obs;

  @override
  void onInit() {
    wishlist.assignAll(
      List.generate(
        5,
        (index) => const Product(
          id: 'w',
          name: '22K Gold Necklace Set',
          price: 28500,
          rating: 4.8,
          tag: '[ Product Image ]',
        ),
      ),
    );
    super.onInit();
  }
}
