import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final ProductModel product;
  int quantity;
}
