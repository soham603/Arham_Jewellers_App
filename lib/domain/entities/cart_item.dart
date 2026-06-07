import 'package:ratnesh_gold_app/domain/entities/productModel.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final ProductModel product;
  int quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
    );
  }
}
