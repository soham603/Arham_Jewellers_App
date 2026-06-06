import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class ShareController extends GetxController {
  final _products = <ProductModel>[].obs;
  List<ProductModel> get products => _products;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  // ── Sort & Layout state ──────────────────────────────────────
  final _sortBy = Rx<SortOption>(SortOption.newest);
  SortOption get sortBy => _sortBy.value;
  Rx<SortOption> get sortByObs => _sortBy;

  final _isGrid = RxBool(true);
  bool get isGrid => _isGrid.value;
  RxBool get isGridObs => _isGrid;

  void setSortOption(SortOption option) {
    _sortBy.value = option;
  }

  void toggleLayout() {
    _isGrid.value = !_isGrid.value;
  }

  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // ── Filter state ─────────────────────────────────────────────
  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  final _selectedKarats = <String>[].obs;
  List<String> get selectedKarats => _selectedKarats;

  final _selectedCategoryIds = <String>[].obs;
  List<String> get selectedCategoryIds => _selectedCategoryIds;

  final _selectedCategoryNames = <String>[].obs;
  List<String> get selectedCategoryNames => _selectedCategoryNames;

  final _stockFilter = 'ready'.obs;
  String get stockFilter => _stockFilter.value;

  final _weightMin = 0.0.obs;
  double get weightMin => _weightMin.value;

  final _weightMax = 500.0.obs;
  double get weightMax => _weightMax.value;

  final _priceMin = 0.0.obs;
  double get priceMin => _priceMin.value;

  final _priceMax = 5000000.0.obs;
  double get priceMax => _priceMax.value;

  final _selectedSizes = <String>[].obs;
  List<String> get selectedSizes => _selectedSizes;

  bool get hasActiveFilters =>
      _selectedKarats.isNotEmpty ||
      _selectedCategoryIds.isNotEmpty ||
      _stockFilter.value != 'ready' ||
      _weightMin.value > 0 ||
      _weightMax.value < 500 ||
      _priceMin.value > 0 ||
      _priceMax.value < 5000000 ||
      _selectedSizes.isNotEmpty;

  int get activeFilterCount {
    var count = _selectedKarats.length;
    if (_selectedCategoryIds.isNotEmpty) count++;
    if (_stockFilter.value != 'ready') count++;
    if (_weightMin.value > 0 || _weightMax.value < 500) count++;
    if (_priceMin.value > 0 || _priceMax.value < 5000000) count++;
    count += _selectedSizes.length;
    return count;
  }

  List<String> get availableSizes {
    final sizes = <String>{};
    for (final p in _products) {
      final s = p.size;
      if (s != null && s.isNotEmpty) sizes.add(s);
    }
    final sorted = sizes.toList()..sort();
    return sorted;
  }

  bool get hasWeightData {
    return _products.any((p) => p.grossWeight != null);
  }

  double get availableWeightMax {
    double max = 0;
    for (final p in _products) {
      final gw = p.grossWeight;
      if (gw != null && gw > max) max = gw;
    }
    return max > 0 ? max.ceilToDouble() : 100;
  }

  // ── Multi-select ─────────────────────────────────────────────
  final _selectedProducts = <String, ProductModel>{}.obs;
  Map<String, ProductModel> get selectedProducts => _selectedProducts;
  int get selectedCount => _selectedProducts.length;

  bool isSelected(String productId) => _selectedProducts.containsKey(productId);

  void toggleSelection(ProductModel product) {
    if (_selectedProducts.containsKey(product.id)) {
      _selectedProducts.remove(product.id);
    } else {
      _selectedProducts[product.id] = product;
    }
  }

  void selectAll() {
    for (final p in _filteredProducts) {
      _selectedProducts[p.id] = p;
    }
  }

  void selectAllFirst(int count) {
    final products = _filteredProducts;
    final limit = count.clamp(0, products.length);
    for (var i = 0; i < limit; i++) {
      _selectedProducts[products[i].id] = products[i];
    }
  }

  bool get areAllSelected =>
      _filteredProducts.isNotEmpty &&
      _filteredProducts.every((p) => _selectedProducts.containsKey(p.id));

  void clearSelection() => _selectedProducts.clear();

  // ── Client-side filtered & sorted list (after API fetch) ─────
  List<ProductModel> get _filteredProducts {
    var list = List<ProductModel>.from(_products);

    if (_weightMin.value > 0 || _weightMax.value < 500) {
      list = list.where((p) {
        final gw = p.grossWeight;
        if (gw == null) return true;
        return gw >= _weightMin.value && gw <= _weightMax.value;
      }).toList();
    }

    if (_priceMin.value > 0 || _priceMax.value < 5000000) {
      list = list.where((p) {
        final price = _calculatePrice(p);
        if (price == null) return true;
        return price >= _priceMin.value && price <= _priceMax.value;
      }).toList();
    }

    if (_selectedSizes.isNotEmpty) {
      list = list.where((p) {
        final s = p.size;
        if (s == null) return false;
        return _selectedSizes.contains(s);
      }).toList();
    }

    list.sort((a, b) {
      switch (_sortBy.value) {
        case SortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.weightAsc:
          return (a.grossWeight ?? 0).compareTo(b.grossWeight ?? 0);
        case SortOption.weightDesc:
          return (b.grossWeight ?? 0).compareTo(a.grossWeight ?? 0);
        case SortOption.newest:
          return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
        case SortOption.oldest:
          return (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
        case SortOption.priceAsc:
          return (_calculatePrice(a) ?? 0).compareTo(_calculatePrice(b) ?? 0);
        case SortOption.priceDesc:
          return (_calculatePrice(b) ?? 0).compareTo(_calculatePrice(a) ?? 0);
      }
    });

    return list;
  }

  List<ProductModel> get displayProducts => _filteredProducts;

  // ── Debounce ─────────────────────────────────────────────────
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  String _karatToSearchValue(String karat) {
    switch (karat) {
      case '9K':
        return '38';
      case '14K':
        return '60';
      case '18K':
        return '76';
      case '20K':
        return '84';
      case '22K':
        return '92';
      case '24K':
        return '100';
      default:
        return karat;
    }
  }

  // ── Product fetching ─────────────────────────────────────────
  Future<void> loadProducts({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _page = 1;
      _hasMore = true;
    }

    try {
      final hasTextQuery = _searchQuery.value.trim().isNotEmpty;
      final hasKaratFilter = _selectedKarats.isNotEmpty;
      final hasCategoryFilter = _selectedCategoryIds.isNotEmpty;

      List<ProductModel> allFetched = [];

      if (hasTextQuery) {
        // ── Text search (with optional client-side karat/category filter) ──
        final response = await httpClient.get(
          "/api/v1/products/search",
          queryParameters: {
            "search": _searchQuery.value.trim(),
            "page": _page,
            "limit": _limit,
            if (_stockFilter.value != 'ready') "showAll": true,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          final List raw = data['data'] is List ? data['data'] : [];
          allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
        }

        if (hasKaratFilter) {
          allFetched = _filterByKarat(allFetched);
        }
        if (hasCategoryFilter) {
          allFetched = _filterByCategoryId(allFetched);
        }
      } else if (hasCategoryFilter) {
        // ── Category filter via /get-all?categoryId=<ID> ──
        for (final categoryId in _selectedCategoryIds) {
          final response = await httpClient.get(
            "/api/v1/products/get-all",
            queryParameters: {
              "categoryId": categoryId,
              "page": _page,
              "limit": _limit,
              "showReverse": true,
              if (_stockFilter.value != 'ready') "showAll": true,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            allFetched.addAll(raw.map((e) => ProductModel.fromJson(e)).toList());
          }
        }

        if (hasKaratFilter) {
          allFetched = _filterByKarat(allFetched);
        }
      } else if (hasKaratFilter) {
        // ── Karat-only via search endpoint ──
        for (final karat in _selectedKarats) {
          final response = await httpClient.get(
            "/api/v1/products/search",
            queryParameters: {
              "search": _karatToSearchValue(karat),
              "page": _page,
              "limit": _limit,
              if (_stockFilter.value != 'ready') "showAll": true,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            allFetched.addAll(raw.map((e) => ProductModel.fromJson(e)).toList());
          }
        }
      } else {
        // ── No filters — use get-all ──
        final response = await httpClient.get(
          "/api/v1/products/get-all",
          queryParameters: {
            "page": _page,
            "limit": _limit,
            "showReverse": true,
            if (_stockFilter.value != 'ready') "showAll": true,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          final List raw = data['data'] is List ? data['data'] : [];
          allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
        }
      }

      // Deduplicate by product ID
      final seen = <String>{};
      allFetched = allFetched.where((p) => seen.add(p.id)).toList();

      if (isPagination) {
        _products.addAll(allFetched);
      } else {
        _products.value = allFetched;
      }

      // Determine expected count for pagination
      int expected;
      if (hasCategoryFilter) {
        expected = _limit * _selectedCategoryIds.length;
      } else if (hasKaratFilter) {
        expected = _limit * _selectedKarats.length;
      } else {
        expected = _limit;
      }

      if (allFetched.length < expected) {
        _hasMore = false;
      } else {
        _page++;
      }

      _state.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("ShareController", "loadProducts error: $e\n$st");
    }
  }

  List<ProductModel> _filterByKarat(List<ProductModel> products) {
    final filterKaratNums = _selectedKarats.map((k) {
      final m = RegExp(r'(\d+)').firstMatch(k);
      return m != null ? int.tryParse(m.group(1)!) : null;
    }).whereType<int>().toSet();
    if (filterKaratNums.isEmpty) return products;
    return products.where((p) {
      final pk = p.karatNumber;
      return pk != null && filterKaratNums.contains(pk);
    }).toList();
  }

  List<ProductModel> _filterByCategoryId(List<ProductModel> products) {
    return products.where((p) {
      final catId = p.category?.id;
      if (catId == null) return false;
      return _selectedCategoryIds.contains(catId);
    }).toList();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;
    await loadProducts(isPagination: true);
  }

  // ── Filter methods ───────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchQuery.value = query;
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      loadProducts();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      loadProducts();
    });
  }

  void onSearchSubmitted(String query) {
    _debounce?.cancel();
    _searchQuery.value = query.trim();
    loadProducts();
  }

  void toggleKaratFilter(String karat) {
    if (_selectedKarats.contains(karat)) {
      _selectedKarats.remove(karat);
    } else {
      _selectedKarats.add(karat);
    }
  }

  void setCategoryFilter(List<String> categoryIds, List<String> categoryNames) {
    _selectedCategoryIds
      ..clear()
      ..addAll(categoryIds);
    _selectedCategoryNames
      ..clear()
      ..addAll(categoryNames);
  }

  void setStockFilter(String val) {
    _stockFilter.value = val;
  }

  void setWeightRange(double min, double max) {
    _weightMin.value = min;
    _weightMax.value = max;
  }

  void clearAllFilters() {
    _selectedKarats.clear();
    _selectedCategoryIds.clear();
    _selectedCategoryNames.clear();
    _stockFilter.value = 'ready';
    _weightMin.value = 0;
    _weightMax.value = 500;
    _priceMin.value = 0;
    _priceMax.value = 5000000;
    _selectedSizes.clear();
  }

  void applyFilters({
    required List<String> karats,
    required List<String> categoryIds,
    required List<String> categoryNames,
    required String stockFilter,
    required double wMin,
    required double wMax,
    required double pMin,
    required double pMax,
    required List<String> sizes,
  }) {
    _selectedKarats
      ..clear()
      ..addAll(karats);
    _selectedCategoryIds
      ..clear()
      ..addAll(categoryIds);
    _selectedCategoryNames
      ..clear()
      ..addAll(categoryNames);
    _stockFilter.value = stockFilter;
    _weightMin.value = wMin;
    _weightMax.value = wMax;
    _priceMin.value = pMin;
    _priceMax.value = pMax;
    _selectedSizes
      ..clear()
      ..addAll(sizes);
    loadProducts();
  }

  // ── Price calculation helper ──────────────────────────────────
  double? _calculatePrice(ProductModel product) {
    final goldRate = Get.find<GoldRateController>().currentRate;
    if (goldRate == null || product.fineWeight == null) return null;
    return GoldRateController.calculatePrice(
      fineWeight: product.fineWeight!,
      ratePer10Gram: goldRate.rate,
    );
  }

  // ── Share methods ───────────────────────────────────────────
  String get filterInfo => ShareService.buildFilterInfo(
        selectedKarats: _selectedKarats,
        selectedCategoryNames: _selectedCategoryNames,
        showAllStock: _stockFilter.value != 'ready',
        weightMin: _weightMin.value,
        weightMax: _weightMax.value,
      );

  List<ProductModel> get selectedProductsList => _selectedProducts.values.toList();

  final _isSharing = false.obs;
  bool get isSharing => _isSharing.value;

  Future<void> shareImages({String? title}) async {
    if (_selectedProducts.isEmpty) return;
    _isSharing.value = true;
    try {
      await ShareService.shareImagesDirectly(
        products: selectedProductsList,
        filterInfo: filterInfo,
        title: title,
      );
    } catch (e, st) {
      Logger.error("ShareController", "shareImages error: $e\n$st");
    } finally {
      _isSharing.value = false;
    }
  }

  Future<void> shareAsPdf({String? title}) async {
    if (_selectedProducts.isEmpty) return;
    _isSharing.value = true;
    try {
      await ShareService.shareAsPdf(
        products: selectedProductsList,
        filterInfo: filterInfo,
        title: title,
      );
    } catch (e, st) {
      Logger.error("ShareController", "shareAsPdf error: $e\n$st");
    } finally {
      _isSharing.value = false;
    }
  }
}
