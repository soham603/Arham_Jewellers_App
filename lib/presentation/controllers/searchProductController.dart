import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchProductController extends GetxController {
  static SearchProductController get instance =>
      Get.isRegistered<SearchProductController>()
      ? Get.find<SearchProductController>()
      : Get.put(SearchProductController());

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;
  static const int _pageLimit = 10;

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

  List<ProductModel> sortProducts(
    List<ProductModel> products,
    SortOption sortBy,
  ) {
    final list = List<ProductModel>.from(products);
    list.sort((a, b) {
      switch (sortBy) {
        case SortOption.weightAsc:
          return (a.grossWeight ?? a.fineWeight ?? 0).compareTo(
            b.grossWeight ?? b.fineWeight ?? 0,
          );
        case SortOption.weightDesc:
          return (b.grossWeight ?? b.fineWeight ?? 0).compareTo(
            a.grossWeight ?? a.fineWeight ?? 0,
          );
        case SortOption.newest:
          return (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          );
        case SortOption.oldest:
          return (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          );
        case SortOption.priceAsc:
          return (_calculatePrice(a) ?? 0).compareTo(_calculatePrice(b) ?? 0);
        case SortOption.priceDesc:
          return (_calculatePrice(b) ?? 0).compareTo(_calculatePrice(a) ?? 0);
      }
    });
    return list;
  }

  // ── Initial load list ────────────────────────────────────────────────────
  final _initialProducts = <ProductModel>[].obs;
  List<ProductModel> get initialProducts => _initialProducts;

  final _initialState = CurrentAppState.INITIAL.obs;
  CurrentAppState get initialState => _initialState.value;

  int _initialPage = 1;
  bool _initialHasMore = true;
  bool get initialHasMore => _initialHasMore;

  // ── Search results list ──────────────────────────────────────────────────
  final _searchResults = <ProductModel>[].obs;
  List<ProductModel> get searchResults => _searchResults;

  final _searchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get searchState => _searchState.value;

  int _searchPage = 1;
  bool _searchHasMore = true;
  bool get searchHasMore => _searchHasMore;

  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;
  bool get isSearching => _searchQuery.value.trim().isNotEmpty;

  // ── Recent searches ──────────────────────────────────────────────────────
  final _recentSearches = <String>[].obs;
  List<String> get recentSearches => _recentSearches;

  // ── Filter state ─────────────────────────────────────────────────────────
  final _selectedKarats = <String>[].obs;
  List<String> get selectedKarats => _selectedKarats;

  final _selectedCategoryId = Rxn<String>();
  String? get selectedCategoryId => _selectedCategoryId.value;

  final _selectedCategoryName = ''.obs;
  String get selectedCategoryName => _selectedCategoryName.value;

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
    final source = allProducts;
    final sizes = <String>{};
    for (final p in source) {
      final s = p.size;
      if (s != null && s.isNotEmpty) sizes.add(s);
    }
    final sorted = sizes.toList()..sort();
    return sorted;
  }

  bool get hasWeightData {
    final source = allProducts;
    return source.any((p) => p.fineWeight != null);
  }

  double get availableWeightMax {
    final source = allProducts;
    double max = 0;
    for (final p in source) {
      final gw = p.fineWeight;
      if (gw != null && gw > max) max = gw;
    }
    return max > 0 ? max.ceilToDouble() : 100;
  }

  // ── Filtered initial products (when filters active, no text search) ──────
  final _filteredInitialProducts = <ProductModel>[].obs;
  List<ProductModel> get filteredInitialProducts => _filteredInitialProducts;

  final _filteredInitialState = CurrentAppState.INITIAL.obs;
  CurrentAppState get filteredInitialState => _filteredInitialState.value;

  int _filteredInitialPage = 1;
  bool _filteredInitialHasMore = true;
  bool get filteredInitialHasMore => _filteredInitialHasMore;

  // ── Debounce ─────────────────────────────────────────────────────────────
  Timer? _debounce;

  bool _hasLoadedInitial = false;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    // Removed: loadInitialProducts() — now called on-demand via ensureProductsLoaded()
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// Ensures initial products are loaded on first use.
  /// Call this when the user first interacts with search or scrolls.
  void ensureProductsLoaded() {
    if (!_hasLoadedInitial && _initialProducts.isEmpty) {
      _hasLoadedInitial = true;
      loadInitialProducts();
    }
  }

  // ── Initial products (no search) ─────────────────────────────────────────
  Future<void> loadInitialProducts({bool isPagination = false}) async {
    if (!_initialHasMore && isPagination) return;
    if (_initialState.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _initialState.value = CurrentAppState.LOADING;
      _initialPage = 1;
      _initialHasMore = true;
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {
          "page": _initialPage,
          "limit": _pageLimit,
          "showReverse": true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _initialProducts.addAll(fetched);
        } else {
          _initialProducts.value = fetched;
        }

        if (fetched.length < _pageLimit) {
          _initialHasMore = false;
        } else {
          _initialPage++;
        }

        _initialState.value = CurrentAppState.SUCCESS;
      } else {
        _initialState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _initialState.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadInitialProducts error: $e\n$st",
      );
    }
  }

  Future<void> loadFilteredProducts({bool isPagination = false}) async {
    if (!_filteredInitialHasMore && isPagination) return;
    if (_filteredInitialState.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _filteredInitialState.value = CurrentAppState.LOADING;
      _filteredInitialPage = 1;
      _filteredInitialHasMore = true;
      _filteredInitialProducts.clear();
    }

    try {
      List<ProductModel> allFetched = [];

      if (_selectedCategoryIds.isNotEmpty) {
        final categoryFutures = _selectedCategoryIds.map((categoryId) async {
          try {
            final response = await httpClient.get(
              "/api/v1/products/get-all",
              queryParameters: {
                "categoryId": categoryId,
                "page": _filteredInitialPage,
                "limit": _pageLimit,
                "showReverse": true,
                if (_stockFilter.value != 'ready') "showAll": true,
              },
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              final data = response.data['data'];
              final List raw = data['data'] is List ? data['data'] : [];
              return raw.map((e) => ProductModel.fromJson(e)).toList();
            }
          } catch (e) {
            Logger.error(
              "SearchProductController",
              "Failed to fetch category $categoryId: $e",
            );
          }
          return <ProductModel>[];
        });
        final results = await Future.wait(categoryFutures);
        allFetched = results.expand((list) => list).toList();
      } else if (_selectedKarats.isNotEmpty) {
        final karatFutures = _selectedKarats.map((karat) async {
          try {
            final response = await httpClient.get(
              "/api/v1/products/search",
              queryParameters: {
                "search": _karatToSearchValue(karat),
                "page": _filteredInitialPage,
                "limit": _pageLimit,
                if (_stockFilter.value != 'ready') "showAll": true,
              },
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              final data = response.data['data'];
              final List raw = data['data'] is List ? data['data'] : [];
              return raw.map((e) => ProductModel.fromJson(e)).toList();
            }
          } catch (e) {
            Logger.error(
              "SearchProductController",
              "Failed to fetch karat $karat: $e",
            );
          }
          return <ProductModel>[];
        });
        final results = await Future.wait(karatFutures);
        allFetched = results.expand((list) => list).toList();
      } else {
        // No filters
        final response = await httpClient.get(
          "/api/v1/products/get-all",
          queryParameters: {
            "page": _filteredInitialPage,
            "limit": _pageLimit,
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

      if (_selectedKarats.isNotEmpty) {
        final filterKaratNums = _selectedKarats
            .map((k) {
              final m = RegExp(r'(\d+)').firstMatch(k);
              return m != null ? int.tryParse(m.group(1)!) : null;
            })
            .whereType<int>()
            .toSet();
        if (filterKaratNums.isNotEmpty) {
          allFetched = allFetched.where((p) {
            final pk = p.karatNumber;
            return pk != null && filterKaratNums.contains(pk);
          }).toList();
        }
      }

      if (_weightMin.value > 0 || _weightMax.value < 500) {
        allFetched = allFetched.where((p) {
          final gw = p.grossWeight;
          if (gw == null) return true;
          return gw >= _weightMin.value && gw <= _weightMax.value;
        }).toList();
      }

      if (_priceMin.value > 0 || _priceMax.value < 5000000) {
        allFetched = allFetched.where((p) {
          final price = _calculatePrice(p);
          if (price == null) return true;
          return price >= _priceMin.value && price <= _priceMax.value;
        }).toList();
      }

      if (_selectedSizes.isNotEmpty) {
        allFetched = allFetched.where((p) {
          final s = p.size;
          if (s == null) return false;
          return _selectedSizes.contains(s);
        }).toList();
      }

      if (isPagination) {
        _filteredInitialProducts.addAll(allFetched);
      } else {
        _filteredInitialProducts.value = allFetched;
      }

      final queryCount = _selectedCategoryIds.isNotEmpty
          ? _selectedCategoryIds.length
          : _selectedKarats.length;
      final expected = _pageLimit * queryCount;
      if (allFetched.length < expected) {
        _filteredInitialHasMore = false;
      } else {
        _filteredInitialPage++;
      }

      _filteredInitialState.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _filteredInitialState.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadFilteredProducts error: $e\n$st",
      );
    }
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;

    if (query.trim().isEmpty) {
      clearSearch();
      if (hasActiveFilters) loadFilteredProducts();
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _runSearch(query.trim(), isPagination: false);
    });
  }

  void onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    _debounce?.cancel();
    _searchQuery.value = query.trim();
    _saveRecentSearch(query.trim());
    _runSearch(query.trim(), isPagination: false);
  }

  Future<void> loadMoreSearchResults() async {
    if (!_searchHasMore || _searchState.value == CurrentAppState.LOADING) {
      return;
    }
    await _runSearch(_searchQuery.value.trim(), isPagination: true);
  }

  Future<void> _runSearch(String query, {required bool isPagination}) async {
    if (_searchState.value == CurrentAppState.LOADING && !isPagination) return;

    if (!isPagination) {
      _searchState.value = CurrentAppState.LOADING;
      _searchPage = 1;
      _searchHasMore = true;
      _searchResults.clear();
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/search",
        queryParameters: {
          "search": query,
          "page": _searchPage,
          "limit": _pageLimit,
          if (_stockFilter.value != 'ready') "showAll": true,
        },
      );

      List<ProductModel> allFetched = [];

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
      }

      if (_selectedKarats.isNotEmpty) {
        final filterKaratNums = _selectedKarats
            .map((k) {
              final m = RegExp(r'(\d+)').firstMatch(k);
              return m != null ? int.tryParse(m.group(1)!) : null;
            })
            .whereType<int>()
            .toSet();
        if (filterKaratNums.isNotEmpty) {
          allFetched = allFetched.where((p) {
            final pk = p.karatNumber;
            return pk != null && filterKaratNums.contains(pk);
          }).toList();
        }
      }

      if (_selectedCategoryIds.isNotEmpty) {
        allFetched = allFetched.where((p) {
          final catId = p.category?.id;
          if (catId == null) return false;
          return _selectedCategoryIds.contains(catId);
        }).toList();
      }

      if (_weightMin.value > 0 || _weightMax.value < 500) {
        allFetched = allFetched.where((p) {
          final gw = p.grossWeight;
          if (gw == null) return true;
          return gw >= _weightMin.value && gw <= _weightMax.value;
        }).toList();
      }

      if (_priceMin.value > 0 || _priceMax.value < 5000000) {
        allFetched = allFetched.where((p) {
          final price = _calculatePrice(p);
          if (price == null) return true;
          return price >= _priceMin.value && price <= _priceMax.value;
        }).toList();
      }

      if (_selectedSizes.isNotEmpty) {
        allFetched = allFetched.where((p) {
          final s = p.size;
          if (s == null) return false;
          return _selectedSizes.contains(s);
        }).toList();
      }

      if (isPagination) {
        _searchResults.addAll(allFetched);
      } else {
        _searchResults.value = allFetched;
      }

      if (allFetched.length < _pageLimit) {
        _searchHasMore = false;
      } else {
        _searchPage++;
      }

      _searchState.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _searchState.value = CurrentAppState.ERROR;
      Logger.error("SearchProductController", "_runSearch error: $e\n$st");
    }
  }

  // ── Karat-filtered products (for "See all" on home page) ───────────────
  final _karatProducts = <ProductModel>[].obs;
  List<ProductModel> get karatProducts => _karatProducts;

  List<ProductModel> get allProducts {
    final source = isSearching ? _searchResults : _filteredInitialProducts;
    if (source.isNotEmpty) return source;
    if (_karatProducts.isNotEmpty) return _karatProducts;
    if (_categoryProducts.isNotEmpty) return _categoryProducts;
    return _initialProducts;
  }

  final _karatState = CurrentAppState.INITIAL.obs;
  CurrentAppState get karatState => _karatState.value;

  List<String> _currentKarats = [];
  int _karatPage = 1;
  bool _karatHasMore = true;
  bool get karatHasMore => _karatHasMore;

  void loadMoreKaratProducts() {
    if (!_karatHasMore || _karatState.value == CurrentAppState.LOADING) return;
    loadProductsByKarats(_currentKarats, isPagination: true);
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

  Future<void> loadProductsByKarats(
    List<String> karats, {
    bool isPagination = false,
  }) async {
    if (!_karatHasMore && isPagination) return;
    if (_karatState.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _currentKarats = karats;
      _karatState.value = CurrentAppState.LOADING;
      _karatPage = 1;
      _karatHasMore = true;
      _karatProducts.clear();
    }

    try {
      final karatFutures = karats.map((karat) async {
        try {
          final response = await httpClient.get(
            "/api/v1/products/search",
            queryParameters: {
              "search": _karatToSearchValue(karat),
              "page": _karatPage,
              "limit": _pageLimit,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            return raw.map((e) => ProductModel.fromJson(e)).toList();
          }
        } catch (e) {
          Logger.error(
            "SearchProductController",
            "Failed to fetch karat $karat: $e",
          );
        }
        return <ProductModel>[];
      });
      final results = await Future.wait(karatFutures);
      final allFetched = results.expand((list) => list).toList();

      if (isPagination) {
        _karatProducts.addAll(allFetched);
      } else {
        _karatProducts.value = allFetched;
      }

      if (allFetched.length < _pageLimit * karats.length) {
        _karatHasMore = false;
      } else {
        _karatPage++;
      }

      _karatState.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _karatState.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadProductsByKarats error: $e\n$st",
      );
    }
  }

  // ── Category-filtered products (for level-3 selection on home page) ────
  final _categoryProducts = <ProductModel>[].obs;
  List<ProductModel> get categoryProducts => _categoryProducts;

  final _categoryState = CurrentAppState.INITIAL.obs;
  CurrentAppState get categoryState => _categoryState.value;

  Future<void> loadProductsByCategory(String categoryId) async {
    _categoryState.value = CurrentAppState.LOADING;
    _categoryProducts.clear();

    try {
      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {
          "categoryId": categoryId,
          "page": 1,
          "limit": _pageLimit,
          "showReverse": true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        _categoryProducts.value = raw
            .map((e) => ProductModel.fromJson(e))
            .toList();
        _categoryState.value = CurrentAppState.SUCCESS;
      } else {
        _categoryState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _categoryState.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadProductsByCategory error: $e\n$st",
      );
    }
  }

  void clearCategoryProducts() {
    _categoryProducts.clear();
    _categoryState.value = CurrentAppState.INITIAL;
  }

  // ── Category + karat filtered products (client-side touch filter) ───
  final _filteredProducts = <ProductModel>[].obs;
  List<ProductModel> get filteredProducts => _filteredProducts;

  final _filteredState = CurrentAppState.INITIAL.obs;
  CurrentAppState get filteredState => _filteredState.value;

  int _filteredPage = 1;
  bool _filteredHasMore = true;
  bool get filteredHasMore => _filteredHasMore;
  String? _currentFilterCategoryId;
  String? _currentFilterKarat;

  void loadMoreFilteredProducts() {
    if (!_filteredHasMore || _filteredState.value == CurrentAppState.LOADING) {
      return;
    }
    loadByCategoryWithKaratFilter(
      _currentFilterCategoryId!,
      _currentFilterKarat!,
      isPagination: true,
    );
  }

  Future<void> loadByCategoryWithKaratFilter(
    String categoryId,
    String targetKarat, {
    bool isPagination = false,
  }) async {
    if (!_filteredHasMore && isPagination) return;
    if (_filteredState.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _currentFilterCategoryId = categoryId;
      _currentFilterKarat = targetKarat;
      _filteredState.value = CurrentAppState.LOADING;
      _filteredPage = 1;
      _filteredHasMore = true;
      _filteredProducts.clear();
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {
          "categoryId": categoryId,
          "page": _filteredPage,
          "limit": _pageLimit,
          "showReverse": true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _filteredProducts.addAll(allFetched);
        } else {
          _filteredProducts.value = allFetched;
        }

        if (allFetched.length < _pageLimit) {
          _filteredHasMore = false;
        } else {
          _filteredPage++;
        }

        _filteredState.value = CurrentAppState.SUCCESS;
      } else {
        _filteredState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _filteredState.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadByCategoryWithKaratFilter error: $e\n$st",
      );
    }
  }

  void clearFilteredProducts() {
    _filteredProducts.clear();
    _filteredState.value = CurrentAppState.INITIAL;
    _filteredPage = 1;
    _filteredHasMore = true;
    _currentFilterCategoryId = null;
    _currentFilterKarat = null;
  }

  void toggleKaratFilter(String karat) {
    if (_selectedKarats.contains(karat)) {
      _selectedKarats.remove(karat);
    } else {
      _selectedKarats.add(karat);
    }
  }

  void setCategoryFilter(String? categoryId, String categoryName) {
    _selectedCategoryId.value = categoryId;
    _selectedCategoryName.value = categoryName;
  }

  void clearAllFilters() {
    _selectedKarats.clear();
    _selectedCategoryId.value = null;
    _selectedCategoryName.value = '';
    _selectedCategoryIds.clear();
    _selectedCategoryNames.clear();
    _stockFilter.value = 'ready';
    _weightMin.value = 0;
    _weightMax.value = 500;
    _priceMin.value = 0;
    _priceMax.value = 5000000;
    _selectedSizes.clear();
    _filteredInitialProducts.clear();
    _filteredInitialState.value = CurrentAppState.INITIAL;
    _filteredInitialPage = 1;
    _filteredInitialHasMore = true;
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
    final karatsCopy = List<String>.from(karats);
    final categoryIdsCopy = List<String>.from(categoryIds);
    final categoryNamesCopy = List<String>.from(categoryNames);
    final sizesCopy = List<String>.from(sizes);

    _selectedKarats
      ..clear()
      ..addAll(karatsCopy);
    _selectedCategoryIds
      ..clear()
      ..addAll(categoryIdsCopy);
    _selectedCategoryNames
      ..clear()
      ..addAll(categoryNamesCopy);
    _selectedCategoryId.value = null;
    _selectedCategoryName.value = '';
    _stockFilter.value = stockFilter;
    _weightMin.value = wMin;
    _weightMax.value = wMax;
    _priceMin.value = pMin;
    _priceMax.value = pMax;
    _selectedSizes
      ..clear()
      ..addAll(sizesCopy);
    if (isSearching) {
      _runSearch(_searchQuery.value.trim(), isPagination: false);
    } else {
      loadFilteredProducts();
    }
  }

  void setStockFilter(String value) {
    if (_stockFilter.value == value) return;
    _stockFilter.value = value;
    if (isSearching) {
      _runSearch(_searchQuery.value.trim(), isPagination: false);
    } else if (hasActiveFilters) {
      loadFilteredProducts();
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    _searchQuery.value = '';
    _searchResults.clear();
    _searchState.value = CurrentAppState.INITIAL;
    _searchPage = 1;
    _searchHasMore = true;
  }

  Future<ProductModel?> searchByBarcode(String barcode) async {
    _searchState.value = CurrentAppState.LOADING;
    _searchQuery.value = '';
    _searchResults.clear();

    try {
      final response = await httpClient.get(
        "/api/v1/products/search",
        queryParameters: {"barcode": barcode},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final inner = data['data'];
        List raw;
        if (inner is List) {
          raw = inner;
        } else if (inner is Map) {
          raw = [inner];
        } else {
          raw = [];
        }
        _searchResults.value = raw
            .map((e) => ProductModel.fromJson(e))
            .toList();
        _searchState.value = CurrentAppState.SUCCESS;
        return _searchResults.isNotEmpty ? _searchResults.first : null;
      } else {
        _searchState.value = CurrentAppState.ERROR;
        return null;
      }
    } catch (e, st) {
      _searchState.value = CurrentAppState.ERROR;
      Logger.error("SearchProductController", "searchByBarcode error: $e\n$st");
      return null;
    }
  }

  // ── Price calculation helper ──────────────────────────────────────────────
  double? _calculatePrice(ProductModel product) {
    final goldRate = Get.find<GoldRateController>().currentRate;
    if (goldRate == null || product.fineWeight == null) return null;
    return GoldRateController.calculatePrice(
      fineWeight:
          product.karigarNetWt ?? 0,
      ratePer10Gram: goldRate.rate,
    );
  }

  // ── Recent searches (SharedPrefs) ────────────────────────────────────────
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentSearchesKey) ?? [];
      _recentSearches.value = saved;
    } catch (e) {
      Logger.error("SearchProductController", "loadRecentSearches error: $e");
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_recentSearchesKey) ?? [];
      final updated = [
        query,
        ...existing.where((s) => s.toLowerCase() != query.toLowerCase()),
      ].take(_maxRecentSearches).toList();

      _recentSearches.value = updated;
      await prefs.setStringList(_recentSearchesKey, updated);
    } catch (e) {
      Logger.error("SearchProductController", "_saveRecentSearch error: $e");
    }
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches.toList());
  }

  Future<void> clearAllRecentSearches() async {
    _recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
