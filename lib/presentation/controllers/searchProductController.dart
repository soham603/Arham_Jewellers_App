import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/search/filter_state.dart';
import 'package:ratnesh_gold_app/presentation/controllers/search/recent_searches.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class SearchProductController extends GetxController {
  static SearchProductController get instance =>
      Get.isRegistered<SearchProductController>()
      ? Get.find<SearchProductController>()
      : Get.put(SearchProductController());

  static const int _pageLimit = 10;

  late final FilterStateController filterState;
  late final RecentSearchesController recentSearchesController;

  final _sortBy = Rx<SortOption>(SortOption.newest);
  SortOption get sortBy => _sortBy.value;
  Rx<SortOption> get sortByObs => _sortBy;

  final _isGrid = RxBool(true);
  bool get isGrid => _isGrid.value;
  RxBool get isGridObs => _isGrid;

  final _initialProducts = <ProductModel>[].obs;
  List<ProductModel> get initialProducts => _initialProducts;

  final _initialState = CurrentAppState.INITIAL.obs;
  CurrentAppState get initialState => _initialState.value;

  int _initialPage = 1;
  bool _initialHasMore = true;
  bool get initialHasMore => _initialHasMore;

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

  List<String> get recentSearches => recentSearchesController.recentSearchesList;

  final _filteredInitialProducts = <ProductModel>[].obs;
  List<ProductModel> get filteredInitialProducts => _filteredInitialProducts;

  final _filteredInitialState = CurrentAppState.INITIAL.obs;
  CurrentAppState get filteredInitialState => _filteredInitialState.value;

  int _filteredInitialPage = 1;
  bool _filteredInitialHasMore = true;
  bool get filteredInitialHasMore => _filteredInitialHasMore;

  Timer? _debounce;
  bool _hasLoadedInitial = false;

  final _karatProducts = <ProductModel>[].obs;
  List<ProductModel> get karatProducts => _karatProducts;

  final _karatState = CurrentAppState.INITIAL.obs;
  CurrentAppState get karatState => _karatState.value;

  List<String> _currentKarats = [];
  int _karatPage = 1;
  bool _karatHasMore = true;
  bool get karatHasMore => _karatHasMore;

  final _categoryProducts = <ProductModel>[].obs;
  List<ProductModel> get categoryProducts => _categoryProducts;

  final _categoryState = CurrentAppState.INITIAL.obs;
  CurrentAppState get categoryState => _categoryState.value;

  final _filteredProducts = <ProductModel>[].obs;
  List<ProductModel> get filteredProducts => _filteredProducts;

  final _filteredState = CurrentAppState.INITIAL.obs;
  CurrentAppState get filteredState => _filteredState.value;

  int _filteredPage = 1;
  bool _filteredHasMore = true;
  bool get filteredHasMore => _filteredHasMore;
  String? _currentFilterCategoryId;
  String? _currentFilterKarat;

  List<String> get selectedKarats => filterState.selectedKaratsValue;
  String? get selectedCategoryId => filterState.selectedCategoryIdValue;
  String get selectedCategoryName => filterState.selectedCategoryNameValue;
  List<String> get selectedCategoryIds => filterState.selectedCategoryIdsValue;
  List<String> get selectedCategoryNames => filterState.selectedCategoryNamesValue;
  String get stockFilter => filterState.stockFilterValue;
  double get weightMin => filterState.weightMinValue;
  double get weightMax => filterState.weightMaxValue;
  List<String> get selectedSizes => filterState.selectedSizesValue;
  double get priceMin => filterState.priceMin;
  double get priceMax => filterState.priceMax;
  bool get hasActiveFilters => filterState.hasActiveFilters;
  int get activeFilterCount => filterState.activeFilterCount;
  List<String> get availableSizes => filterState.availableSizes;
  bool get hasWeightData => filterState.hasWeightData;
  double get availableWeightMax => filterState.availableWeightMax;

  List<ProductModel> get allProducts {
    final source = isSearching ? _searchResults : _filteredInitialProducts;
    if (source.isNotEmpty) return source;
    if (_karatProducts.isNotEmpty) return _karatProducts;
    if (_categoryProducts.isNotEmpty) return _categoryProducts;
    return _initialProducts;
  }

  @override
  void onInit() {
    super.onInit();
    filterState = FilterStateController();
    recentSearchesController = RecentSearchesController();
    recentSearchesController.loadRecentSearches();
    filterState.setProductsProvider(() => allProducts);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void setSortOption(SortOption option) {
    _sortBy.value = option;
  }

  void toggleLayout() {
    _isGrid.value = !_isGrid.value;
  }

  List<ProductModel> _dedupe(List<ProductModel> incoming, List<ProductModel> existing) {
    final existingIds = existing.map((p) => p.id).toSet();
    return incoming.where((p) => existingIds.add(p.id)).toList();
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

  void ensureProductsLoaded() {
    if (!_hasLoadedInitial && _initialProducts.isEmpty) {
      _hasLoadedInitial = true;
      loadInitialProducts();
    }
  }

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
          _initialProducts.addAll(_dedupe(fetched, _initialProducts));
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

      if (filterState.selectedCategoryIds.isNotEmpty) {
        final categoryFutures =
            filterState.selectedCategoryIds.map((categoryId) async {
          try {
            final response = await httpClient.get(
              "/api/v1/products/get-all",
              queryParameters: {
                "categoryId": categoryId,
                "page": _filteredInitialPage,
                "limit": _pageLimit,
                "showReverse": true,
                if (filterState.stockFilter.value != 'ready') "showAll": true,
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
      } else if (filterState.selectedKarats.isNotEmpty) {
        final karatFutures = filterState.selectedKarats.map((karat) async {
          try {
            final response = await httpClient.get(
              "/api/v1/products/search",
              queryParameters: {
                "search": _karatToSearchValue(karat),
                "page": _filteredInitialPage,
                "limit": _pageLimit,
                if (filterState.stockFilter.value != 'ready') "showAll": true,
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
        final response = await httpClient.get(
          "/api/v1/products/get-all",
          queryParameters: {
            "page": _filteredInitialPage,
            "limit": _pageLimit,
            "showReverse": true,
            if (filterState.stockFilter.value != 'ready') "showAll": true,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          final List raw = data['data'] is List ? data['data'] : [];
          allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
        }
      }

      final seen = <String>{};
      allFetched = allFetched.where((p) => seen.add(p.id)).toList();

      if (filterState.selectedKarats.isNotEmpty) {
        final filterKaratNums = filterState.selectedKarats
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

      if (filterState.weightMin.value > 0 ||
          filterState.weightMax.value < 500) {
        allFetched = allFetched.where((p) {
          final gw = p.grossWeight;
          if (gw == null) return true;
          return gw >= filterState.weightMin.value &&
              gw <= filterState.weightMax.value;
        }).toList();
      }

      if (filterState.selectedSizes.isNotEmpty) {
        allFetched = allFetched.where((p) {
          final s = p.size;
          if (s == null) return false;
          return filterState.selectedSizes.contains(s);
        }).toList();
      }

      if (isPagination) {
        _filteredInitialProducts.addAll(_dedupe(allFetched, _filteredInitialProducts));
      } else {
        _filteredInitialProducts.value = allFetched;
      }

      final queryCount = filterState.selectedCategoryIds.isNotEmpty
          ? filterState.selectedCategoryIds.length
          : filterState.selectedKarats.length;
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
    recentSearchesController.addToRecentSearches(query.trim());
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
          if (filterState.stockFilter.value != 'ready') "showAll": true,
        },
      );

      List<ProductModel> allFetched = [];

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
      }

      if (filterState.selectedKarats.isNotEmpty) {
        final filterKaratNums = filterState.selectedKarats
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

      if (filterState.selectedCategoryIds.isNotEmpty) {
        allFetched = allFetched.where((p) {
          final catId = p.category?.id;
          if (catId == null) return false;
          return filterState.selectedCategoryIds.contains(catId);
        }).toList();
      }

      if (filterState.weightMin.value > 0 ||
          filterState.weightMax.value < 500) {
        allFetched = allFetched.where((p) {
          final gw = p.grossWeight;
          if (gw == null) return true;
          return gw >= filterState.weightMin.value &&
              gw <= filterState.weightMax.value;
        }).toList();
      }

      if (filterState.selectedSizes.isNotEmpty) {
        allFetched = allFetched.where((p) {
          final s = p.size;
          if (s == null) return false;
          return filterState.selectedSizes.contains(s);
        }).toList();
      }

      if (isPagination) {
        _searchResults.addAll(_dedupe(allFetched, _searchResults));
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

    _karatState.value = CurrentAppState.LOADING;

    if (!isPagination) {
      _currentKarats = karats;
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
      final allFetched = _dedupe(results.expand((list) => list).toList(), _karatProducts);

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

  void loadMoreKaratProducts() {
    if (!_karatHasMore || _karatState.value == CurrentAppState.LOADING) return;
    loadProductsByKarats(_currentKarats, isPagination: true);
  }

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
        _categoryProducts.value =
            raw.map((e) => ProductModel.fromJson(e)).toList();
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

  Future<void> loadProductsByMultipleCategories(List<String> categoryIds) async {
    _categoryState.value = CurrentAppState.LOADING;
    _categoryProducts.clear();

    try {
      final futures = categoryIds.map((catId) async {
        try {
          final response = await httpClient.get(
            "/api/v1/products/get-all",
            queryParameters: {
              "categoryId": catId,
              "page": 1,
              "limit": _pageLimit,
              "showReverse": true,
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
            "Failed to fetch category $catId: $e",
          );
        }
        return <ProductModel>[];
      });

      final results = await Future.wait(futures);
      final seenIds = <String>{};
      final allProducts = <ProductModel>[];

      for (final products in results) {
        for (final p in products) {
          if (seenIds.add(p.id)) {
            allProducts.add(p);
          }
        }
      }

      _categoryProducts.value = allProducts;
      _categoryState.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _categoryState.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadProductsByMultipleCategories error: $e\n$st",
      );
    }
  }

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

    _filteredState.value = CurrentAppState.LOADING;

    if (!isPagination) {
      _currentFilterCategoryId = categoryId;
      _currentFilterKarat = targetKarat;
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
          _filteredProducts.addAll(_dedupe(allFetched, _filteredProducts));
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
    filterState.toggleKaratFilter(karat);
  }

  void setCategoryFilter(String? categoryId, String categoryName) {
    filterState.setCategoryFilter(categoryId, categoryName);
  }

  void clearAllFilters() {
    filterState.resetFilters();
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
    filterState.applyFrom(
      karats: karats,
      categoryIds: categoryIds,
      categoryNames: categoryNames,
      stock: stockFilter,
      wMin: wMin,
      wMax: wMax,
      sizes: sizes,
    );
    if (isSearching) {
      _runSearch(_searchQuery.value.trim(), isPagination: false);
    } else {
      loadFilteredProducts();
    }
  }

  void setStockFilter(String value) {
    filterState.setStockFilter(value);
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
        _searchResults.value =
            raw.map((e) => ProductModel.fromJson(e)).toList();
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

  double? _calculatePrice(ProductModel product) {
    final goldRate = Get.find<GoldRateController>().currentRate;
    if (goldRate == null || product.fineWeight == null) return null;
    return GoldRateController.calculatePrice(
      fineWeight: product.karigarNetWt ?? 0,
      ratePer10Gram: goldRate.rate,
    );
  }

  Future<void> removeRecentSearch(String query) async {
    await recentSearchesController.removeFromRecentSearches(query);
  }

  Future<void> clearAllRecentSearches() async {
    await recentSearchesController.clearRecentSearches();
  }
}
