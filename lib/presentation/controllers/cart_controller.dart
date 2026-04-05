import 'package:get/get.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

class CartController extends GetxController {
  final items = <CartItem>[].obs;

  @override
  void onInit() {
    items.assignAll(
      [
        CartItem(product: const Product(id: 'c1', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]')),
        CartItem(product: const Product(id: 'c2', name: 'Diamond Earrings', price: 8900, rating: 4.8, tag: '[ Product Image ]')),
        CartItem(product: const Product(id: 'c3', name: 'Gold Bangle', price: 22100, rating: 4.8, tag: '[ Product Image ]')),
      ],
    );
    super.onInit();
  }

  int get subtotal => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  void increment(int index) {
    items[index].quantity += 1;
    items.refresh();
  }

  void decrement(int index) {
    if (items[index].quantity > 1) {
      items[index].quantity -= 1;
      items.refresh();
    }
  }

  void remove(int index) {
    items.removeAt(index);
  }
}
