import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';

class FilterStateController extends GetxController {
  List<ProductModel> Function()? _productsProvider;

  void setProductsProvider(List<ProductModel> Function() provider) {
    _productsProvider = provider;
  }

  List<ProductModel> get _products => _productsProvider?.call() ?? [];

  final stockFilter = 'ready'.obs;
  String get stockFilterValue => stockFilter.value;

  final weightMin = 0.0.obs;
  double get weightMinValue => weightMin.value;

  final weightMax = 500.0.obs;
  double get weightMaxValue => weightMax.value;

  final selectedSizes = <String>[].obs;
  List<String> get selectedSizesValue => selectedSizes;

  final selectedKarats = <String>[].obs;
  List<String> get selectedKaratsValue => selectedKarats;

  final selectedCategoryId = Rxn<String>();
  String? get selectedCategoryIdValue => selectedCategoryId.value;

  final selectedCategoryName = ''.obs;
  String get selectedCategoryNameValue => selectedCategoryName.value;

  final selectedCategoryIds = <String>[].obs;
  List<String> get selectedCategoryIdsValue => selectedCategoryIds;

  final selectedCategoryNames = <String>[].obs;
  List<String> get selectedCategoryNamesValue => selectedCategoryNames;

  double get priceMin => 0;
  double get priceMax => 5000000;

  bool get hasActiveFilters =>
      selectedKarats.isNotEmpty ||
      selectedCategoryIds.isNotEmpty ||
      stockFilter.value != 'ready' ||
      weightMin.value > 0 ||
      weightMax.value < 500 ||
      selectedSizes.isNotEmpty;

  int get activeFilterCount {
    var count = selectedKarats.length;
    if (selectedCategoryIds.isNotEmpty) count++;
    if (stockFilter.value != 'ready') count++;
    if (weightMin.value > 0 || weightMax.value < 500) count++;
    count += selectedSizes.length;
    return count;
  }

  List<String> get availableSizes {
    final source = _products;
    final sizes = <String>{};
    for (final p in source) {
      final s = p.size;
      if (s != null && s.isNotEmpty) sizes.add(s);
    }
    final sorted = sizes.toList()..sort();
    return sorted;
  }

  bool get hasWeightData {
    final source = _products;
    return source.any((p) => p.fineWeight != null);
  }

  double get availableWeightMax {
    final source = _products;
    double max = 0;
    for (final p in source) {
      final gw = p.fineWeight;
      if (gw != null && gw > max) max = gw;
    }
    return max > 0 ? max.ceilToDouble() : 100;
  }

  void setStockFilter(String value) {
    if (stockFilter.value == value) return;
    stockFilter.value = value;
  }

  void toggleKaratFilter(String karat) {
    if (selectedKarats.contains(karat)) {
      selectedKarats.remove(karat);
    } else {
      selectedKarats.add(karat);
    }
  }

  void setCategoryFilter(String? categoryId, String categoryName) {
    selectedCategoryId.value = categoryId;
    selectedCategoryName.value = categoryName;
  }

  void toggleSize(String size) {
    if (selectedSizes.contains(size)) {
      selectedSizes.remove(size);
    } else {
      selectedSizes.add(size);
    }
  }

  void setWeightRange(double min, double max) {
    weightMin.value = min;
    weightMax.value = max;
  }

  void resetFilters() {
    selectedKarats.clear();
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    selectedCategoryIds.clear();
    selectedCategoryNames.clear();
    stockFilter.value = 'ready';
    weightMin.value = 0;
    weightMax.value = 500;
    selectedSizes.clear();
  }

  void applyFrom({
    required List<String> karats,
    required List<String> categoryIds,
    required List<String> categoryNames,
    required String stock,
    required double wMin,
    required double wMax,
    required List<String> sizes,
  }) {
    selectedKarats
      ..clear()
      ..addAll(karats);
    selectedCategoryIds
      ..clear()
      ..addAll(categoryIds);
    selectedCategoryNames
      ..clear()
      ..addAll(categoryNames);
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    stockFilter.value = stock;
    weightMin.value = wMin;
    weightMax.value = wMax;
    selectedSizes
      ..clear()
      ..addAll(sizes);
  }
}
