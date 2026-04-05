class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.tag,
  });

  final String id;
  final String name;
  final int price;
  final double rating;
  final String tag;
}
