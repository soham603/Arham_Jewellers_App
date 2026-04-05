import '../../domain/entities/product.dart';

class MockCatalogRepository {
  const MockCatalogRepository();

  List<Product> trendingProducts() {
    return const [
      Product(id: 'p1', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]'),
      Product(id: 'p2', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]'),
      Product(id: 'p3', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]'),
      Product(id: 'p4', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]'),
      Product(id: 'p5', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]'),
      Product(id: 'p6', name: '22K Gold Ring', price: 12450, rating: 4.8, tag: '[ Product Image ]'),
    ];
  }

  List<String> categories() {
    return const ['Gold', 'Diamond', 'Rings', 'Earrings'];
  }

  List<String> recentSearches() {
    return const ['Gold Necklace', 'Diamond Ring', 'Bangles 22K', 'Earrings'];
  }
}
