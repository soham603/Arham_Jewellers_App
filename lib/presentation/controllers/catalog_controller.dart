import 'package:get/get.dart';

import '../../data/repositories/mock_catalog_repository.dart';
import '../../domain/entities/product.dart';

class CatalogController extends GetxController {
  CatalogController({MockCatalogRepository? repository}) : _repository = repository ?? const MockCatalogRepository();

  final MockCatalogRepository _repository;

  late final List<Product> products;
  late final List<String> categories;
  late final List<String> recentSearches;

  @override
  void onInit() {
    products = _repository.trendingProducts();
    categories = _repository.categories();
    recentSearches = _repository.recentSearches();
    super.onInit();
  }
}
