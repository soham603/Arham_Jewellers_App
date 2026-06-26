import 'dart:convert';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/cart_item.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find();

  static const String _cartKey = 'persisted_cart';

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
      (sum, item) {
        final price = GoldRateController.calculatePrice(
          fineWeight: item.product.karigarNetWt ?? 0,
          ratePer10Gram: Get.find<GoldRateController>().currentRate?.rate ?? 0,
        );
        return sum + ((price ?? 0) * item.quantity);
      },
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
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: 1,
        ),
      );
    }
    _saveCart();
  }

  void removeFromCart(String productId) {
    _items.removeWhere(
      (e) => e.product.id == productId,
    );
    _saveCart();
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere(
      (e) => e.product.id == productId,
    );

    if (index == -1) return;

    _items[index].quantity += 1;
    _items.refresh();
    _saveCart();
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
    _saveCart();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
  }

  @override
  void onInit() {
    super.onInit();
    _loadCart();
  }

  @override
  void onClose() {
    _items.clear();
    super.onClose();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        final loadedItems = decoded
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _items.addAll(loadedItems);
      } catch (e, st) {
        Logger.error("CartController", "Failed to load cart from SharedPreferences, clearing corrupted data", stackTrace: st);
        await prefs.remove(_cartKey);
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
  }
}