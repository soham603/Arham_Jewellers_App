import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/cart_item.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final RxList<CartItem> _items = <CartItem>[].obs;

  List<CartItem> get items => _items;

  int get totalItems {
    return _items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) =>
          sum +
          ((item.product.rawData?["TagSalesAmount"] ?? 0)
                  .toDouble() *
              item.quantity),
    );
  }

  bool isInCart(String productId) {
    return _items.any(
      (e) => e.product.id == productId,
    );
  }

  int getProductQuantity(String productId) {
    final index = _items.indexWhere(
      (e) => e.product.id == productId,
    );

    if (index == -1) return 0;

    return _items[index].quantity;
  }

  void addToCart(ProductModel product) {
    final index = _items.indexWhere(
      (e) => e.product.id == product.id,
    );

    if (index != -1) {
      _items[index].quantity += 1;
      _items.refresh();
      return;
    }
    _items.add(
      CartItem(
        product: product,
        quantity: 1,
      ),
    );
  }

  void removeFromCart(String productId) {
    _items.removeWhere(
      (e) => e.product.id == productId,
    );
  }
  void incrementQuantity(String productId) {
    final index = _items.indexWhere(
      (e) => e.product.id == productId,
    );

    if (index == -1) return;

    _items[index].quantity += 1;
    _items.refresh();
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere(
      (e) => e.product.id == productId,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
    } else {
      _items.removeAt(index);
    }

    _items.refresh();
  }

  void clearCart() {
    _items.clear();
  }
}