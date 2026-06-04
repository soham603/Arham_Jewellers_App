import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class ShareController extends GetxController {
  final _products = <ProductModel>[].obs;
  List<ProductModel> get products => _products;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

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

  final _showAllStock = false.obs;
  bool get showAllStock => _showAllStock.value;

  final _weightMin = 0.0.obs;
  double get weightMin => _weightMin.value;

  final _weightMax = 500.0.obs;
  double get weightMax => _weightMax.value;

  bool get hasActiveFilters =>
      _selectedKarats.isNotEmpty ||
      _selectedCategoryIds.isNotEmpty ||
      _showAllStock.value ||
      _weightMin.value > 0 ||
      _weightMax.value < 500;

  int get activeFilterCount {
    var count = _selectedKarats.length;
    if (_selectedCategoryIds.isNotEmpty) count++;
    if (_showAllStock.value) count++;
    if (_weightMin.value > 0 || _weightMax.value < 500) count++;
    return count;
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

  void clearSelection() => _selectedProducts.clear();

  // ── Client-side filtered list (after API fetch) ──────────────
  List<ProductModel> get _filteredProducts {
    var list = List<ProductModel>.from(_products);

    if (_weightMin.value > 0 || _weightMax.value < 500) {
      list = list.where((p) {
        final gw = p.grossWeight;
        if (gw == null) return true;
        return gw >= _weightMin.value && gw <= _weightMax.value;
      }).toList();
    }

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

      if (hasTextQuery || hasKaratFilter || hasCategoryFilter) {
        final List<String> searchQueries = [];

        if (hasCategoryFilter && _selectedCategoryNames.isNotEmpty) {
          final cleanedNames = _selectedCategoryNames
              .map((n) => n
                  .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                  .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                  .trim())
              .where((n) => n.isNotEmpty)
              .toList();

          if (hasKaratFilter) {
            for (final karat in _selectedKarats) {
              for (final name in cleanedNames) {
                searchQueries.add("${_karatToSearchValue(karat)} $name");
              }
            }
          } else if (hasTextQuery) {
            for (final name in cleanedNames) {
              searchQueries.add("${_searchQuery.value.trim()} $name");
            }
          } else {
            searchQueries.addAll(cleanedNames);
          }
        } else if (hasKaratFilter) {
          for (final karat in _selectedKarats) {
            if (hasTextQuery) {
              searchQueries.add("${_searchQuery.value.trim()} ${_karatToSearchValue(karat)}");
            } else {
              searchQueries.add(_karatToSearchValue(karat));
            }
          }
        } else if (hasTextQuery) {
          searchQueries.add(_searchQuery.value.trim());
        }

        for (final q in searchQueries) {
          final response = await httpClient.get(
            "/api/v1/products/search",
            queryParameters: {
              "search": q,
              "page": _page,
              "limit": _limit,
              if (_showAllStock.value) "showAll": true,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            allFetched.addAll(
              raw.map((e) => ProductModel.fromJson(e)).toList(),
            );
          }
        }
      } else {
        // No filters — use get-all
        final response = await httpClient.get(
          "/api/v1/products/get-all",
          queryParameters: {
            "page": _page,
            "limit": _limit,
            if (_showAllStock.value) "showAll": true,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          final List raw = data['data'] is List ? data['data'] : [];
          allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
        }
      }

      if (isPagination) {
        _products.addAll(allFetched);
      } else {
        _products.value = allFetched;
      }

      final expected = hasKaratFilter ? _limit * _selectedKarats.length : _limit;
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

  void setShowAllStock(bool val) {
    _showAllStock.value = val;
  }

  void setWeightRange(double min, double max) {
    _weightMin.value = min;
    _weightMax.value = max;
  }

  void clearAllFilters() {
    _selectedKarats.clear();
    _selectedCategoryIds.clear();
    _selectedCategoryNames.clear();
    _showAllStock.value = false;
    _weightMin.value = 0;
    _weightMax.value = 500;
  }

  void applyFilters({
    required List<String> karats,
    required List<String> categoryIds,
    required List<String> categoryNames,
    required bool showAll,
    required double wMin,
    required double wMax,
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
    _showAllStock.value = showAll;
    _weightMin.value = wMin;
    _weightMax.value = wMax;
    loadProducts();
  }

  // ── Share methods ───────────────────────────────────────────
  String get filterInfo => ShareService.buildFilterInfo(
        selectedKarats: _selectedKarats,
        selectedCategoryNames: _selectedCategoryNames,
        showAllStock: _showAllStock.value,
        weightMin: _weightMin.value,
        weightMax: _weightMax.value,
      );

  List<ProductModel> get selectedProductsList => _selectedProducts.values.toList();

  final _isSharing = false.obs;
  bool get isSharing => _isSharing.value;

  Future<void> shareImages() async {
    if (_selectedProducts.isEmpty) return;
    _isSharing.value = true;
    try {
      await ShareService.shareImagesDirectly(
        products: selectedProductsList,
        filterInfo: filterInfo,
      );
    } catch (e, st) {
      Logger.error("ShareController", "shareImages error: $e\n$st");
    } finally {
      _isSharing.value = false;
    }
  }

  Future<void> shareAsPdf() async {
    if (_selectedProducts.isEmpty) return;
    _isSharing.value = true;
    try {
      await ShareService.shareAsPdf(
        products: selectedProductsList,
        filterInfo: filterInfo,
      );
    } catch (e, st) {
      Logger.error("ShareController", "shareAsPdf error: $e\n$st");
    } finally {
      _isSharing.value = false;
    }
  }
}
