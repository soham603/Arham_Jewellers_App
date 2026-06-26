import 'dart:convert';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistController extends GetxController {
  static WishlistController get instance => Get.find();

  static const String _wishlistKey = 'persisted_wishlist';

  final RxList<ProductModel> _items = <ProductModel>[].obs;

  List<ProductModel> get items => _items;

  int get totalItems => _items.length;

  bool isWishlisted(String productId) {
    return _items.any((e) => e.id == productId);
  }

  void addToWishlist(ProductModel product) {
    if (!isWishlisted(product.id)) {
      _items.add(product);
      _saveWishlist();
    }
  }

  void toggleWishlist(ProductModel product) {
    final index = _items.indexWhere((e) => e.id == product.id);
    if (index != -1) {
      _items.removeAt(index);
    } else {
      _items.add(product);
    }
    _saveWishlist();
  }

  void removeFromWishlist(String productId) {
    _items.removeWhere((e) => e.id == productId);
    _saveWishlist();
  }

  void clearWishlist() {
    _items.clear();
    _saveWishlist();
  }

  @override
  void onInit() {
    super.onInit();
    _loadWishlist();
  }

  @override
  void onClose() {
    _items.clear();
    super.onClose();
  }

  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getString(_wishlistKey);
    if (wishlistJson != null && wishlistJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(wishlistJson);
        final loadedItems = decoded
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _items.addAll(loadedItems);
      } catch (e, st) {
        Logger.error("WishlistController", "Failed to load wishlist from SharedPreferences", stackTrace: st);
        await prefs.remove(_wishlistKey);
      }
    }
  }

  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_wishlistKey, wishlistJson);
  }
}
