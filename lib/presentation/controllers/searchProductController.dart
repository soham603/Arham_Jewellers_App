import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/karat_constants.dart';
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

  final _layoutType = Rx<LayoutType>(LayoutType.grid);
  LayoutType get layoutType => _layoutType.value;
  Rx<LayoutType> get layoutTypeObs => _layoutType;
  bool get isGrid => _layoutType.value == LayoutType.grid;

  final _initialProducts = <ProductModel>[].obs;
  List<ProductModel> get initialProducts => _initialProducts;

  final _initialState = CurrentAppState.INITIAL.obs;
  CurrentAppState get initialState => _initialState.value;

  bool _initialHasMore = true;
  bool get initialHasMore => _initialHasMore;

  final _searchResults = <ProductModel>[].obs;
  List<ProductModel> get searchResults => _searchResults;

  final _searchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get searchState => _searchState.value;

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

  bool _filteredInitialHasMore = true;
  bool get filteredInitialHasMore => _filteredInitialHasMore;

  final _karatProducts = <ProductModel>[].obs;
  List<ProductModel> get karatProducts => _karatProducts;

  final _karatState = CurrentAppState.INITIAL.obs;
  CurrentAppState get karatState => _karatState.value;

  List<String> _currentKarats = [];
  final bool _karatHasMore = true;
  bool get karatHasMore => _karatHasMore;

  final _karatReadyProducts = <ProductModel>[].obs;
  final _karatOutProducts = <ProductModel>[].obs;
  final _karatAllProducts = <ProductModel>[].obs;

  final _karatReadyState = CurrentAppState.INITIAL.obs;
  final _karatOutState = CurrentAppState.INITIAL.obs;
  final _karatAllState = CurrentAppState.INITIAL.obs;

  int _karatReadyPage = 1;
  int _karatOutPage = 1;
  int _karatAllPage = 1;

  bool _karatReadyHasMore = true;
  bool _karatOutHasMore = true;
  bool _karatAllHasMore = true;

  List<ProductModel> get karatReadyProducts => _karatReadyProducts;
  List<ProductModel> get karatOutProducts => _karatOutProducts;
  List<ProductModel> get karatAllProducts => _karatAllProducts;

  CurrentAppState get karatReadyState => _karatReadyState.value;
  CurrentAppState get karatOutState => _karatOutState.value;
  CurrentAppState get karatAllState => _karatAllState.value;

  bool get karatReadyHasMore => _karatReadyHasMore;
  bool get karatOutHasMore => _karatOutHasMore;
  bool get karatAllHasMore => _karatAllHasMore;

  final _categoryProducts = <ProductModel>[].obs;
  List<ProductModel> get categoryProducts => _categoryProducts;

  final _categoryState = CurrentAppState.INITIAL.obs;
  CurrentAppState get categoryState => _categoryState.value;

  final _categoryReadyProducts = <ProductModel>[].obs;
  final _categoryOutProducts = <ProductModel>[].obs;
  final _categoryAllProducts = <ProductModel>[].obs;

  final _categoryReadyState = CurrentAppState.INITIAL.obs;
  final _categoryOutState = CurrentAppState.INITIAL.obs;
  final _categoryAllState = CurrentAppState.INITIAL.obs;

  bool _categoryReadyHasMore = true;
  bool _categoryOutHasMore = true;
  bool _categoryAllHasMore = true;

  int _multiCategoryReadyPage = 1;
  int _multiCategoryOutPage = 1;
  int _multiCategoryAllPage = 1;

  List<String> _currentMultiCategoryIds = [];

  List<ProductModel> get categoryReadyProducts => _categoryReadyProducts;
  List<ProductModel> get categoryOutProducts => _categoryOutProducts;
  List<ProductModel> get categoryAllProducts => _categoryAllProducts;

  CurrentAppState get categoryReadyState => _categoryReadyState.value;
  CurrentAppState get categoryOutState => _categoryOutState.value;
  CurrentAppState get categoryAllState => _categoryAllState.value;

  bool get categoryReadyHasMore => _categoryReadyHasMore;
  bool get categoryOutHasMore => _categoryOutHasMore;
  bool get categoryAllHasMore => _categoryAllHasMore;

  final _filteredProducts = <ProductModel>[].obs;
  List<ProductModel> get filteredProducts => _filteredProducts;

  final _filteredState = CurrentAppState.INITIAL.obs;
  CurrentAppState get filteredState => _filteredState.value;

  bool _filteredHasMore = true;
  bool get filteredHasMore => _filteredHasMore;

  final _filteredReadyProducts = <ProductModel>[].obs;
  final _filteredOutProducts = <ProductModel>[].obs;
  final _filteredAllProducts = <ProductModel>[].obs;

  final _filteredReadyState = CurrentAppState.INITIAL.obs;
  final _filteredOutState = CurrentAppState.INITIAL.obs;
  final _filteredAllState = CurrentAppState.INITIAL.obs;

  int _filteredReadyPage = 1;
  int _filteredOutPage = 1;
  int _filteredAllPage = 1;

  bool _filteredReadyHasMore = true;
  bool _filteredOutHasMore = true;
  bool _filteredAllHasMore = true;

  String? _currentFilterCategoryIdForReady;
  String? _currentFilterKaratForReady;
  String? _currentFilterCategoryIdForOut;
  String? _currentFilterKaratForOut;
  String? _currentFilterCategoryIdForAll;
  String? _currentFilterKaratForAll;

  List<ProductModel> get filteredReadyProducts => _filteredReadyProducts;
  List<ProductModel> get filteredOutProducts => _filteredOutProducts;
  List<ProductModel> get filteredAllProducts => _filteredAllProducts;

  CurrentAppState get filteredReadyState => _filteredReadyState.value;
  CurrentAppState get filteredOutState => _filteredOutState.value;
  CurrentAppState get filteredAllState => _filteredAllState.value;

  bool get filteredReadyHasMore => _filteredReadyHasMore;
  bool get filteredOutHasMore => _filteredOutHasMore;
  bool get filteredAllHasMore => _filteredAllHasMore;

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
    if (isSearching) return _searchResults;
    if (hasActiveFilters) return _filteredInitialProducts;
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
    ever(_sortBy, (_) => _applySortToCurrentResults());
  }

  @override
  void onClose() {
    filterState.dispose();
    recentSearchesController.dispose();
    super.onClose();
  }

  void setSortOption(SortOption option) {
    _sortBy.value = option;
  }

  void _applySortToCurrentResults() {
    final current = _sortBy.value;
    if (isSearching) {
      _searchResults.value = sortProducts(_searchResults, current);
    } else if (hasActiveFilters) {
      _filteredInitialProducts.value = sortProducts(_filteredInitialProducts, current);
    } else {
      _initialProducts.value = sortProducts(_initialProducts, current);
    }
  }

  void toggleLayout() {
    switch (_layoutType.value) {
      case LayoutType.grid:
        _layoutType.value = LayoutType.list;
        break;
      case LayoutType.list:
        _layoutType.value = LayoutType.fullScreen;
        break;
      case LayoutType.fullScreen:
        _layoutType.value = LayoutType.grid;
        break;
    }
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

  void ensureProductsLoaded() {}

  Future<void> loadInitialProducts({bool isPagination = false}) async {}

  Future<void> loadFilteredProducts({bool isPagination = false}) async {}

  void onSearchChanged(String query) {
    _searchQuery.value = query;

    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
  }

  void onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    _searchQuery.value = query.trim();
    recentSearchesController.addToRecentSearches(query.trim());
  }

  Future<void> loadMoreSearchResults() async {}

  String _karatToSearchValue(String karat) {
    final value = KaratConstants.touchValueFor(karat);
    return value != 0 ? value.toString() : karat;
  }

  Map<String, int>? _stockQueryParam(String? stockFilter) {
    if (stockFilter == 'ready') return {"isStock": 1};
    if (stockFilter == 'out') return {"isStock": 0};
    return null;
  }

  Future<void> loadProductsByKarats(
    List<String> karats, {
    bool isPagination = false,
    String? stockFilter,
  }) async {
    _currentKarats = karats;
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';

    final page = isReady ? _karatReadyPage : isOut ? _karatOutPage : _karatAllPage;
    final hasMore = isReady ? _karatReadyHasMore : isOut ? _karatOutHasMore : _karatAllHasMore;
    final state = isReady ? _karatReadyState : isOut ? _karatOutState : _karatAllState;

    if (!hasMore && isPagination) return;
    if (state.value == CurrentAppState.LOADING) return;

    state.value = CurrentAppState.LOADING;

    int currentPage = page;
    bool currentHasMore = hasMore;

    if (!isPagination) {
      currentPage = 1;
      currentHasMore = true;
      if (isReady) {
        _karatReadyPage = 1;
        _karatReadyHasMore = true;
        _karatReadyProducts.clear();
      } else if (isOut) {
        _karatOutPage = 1;
        _karatOutHasMore = true;
        _karatOutProducts.clear();
      } else {
        _karatAllPage = 1;
        _karatAllHasMore = true;
        _karatAllProducts.clear();
      }
    }

    try {
      final stockParam = _stockQueryParam(stockFilter);
      final karatFutures = karats.map((karat) async {
        try {
          final response = await httpClient.get(
            ApiUrlConstants.PRODUCTS_SEARCH,
            queryParameters: {
              "search": _karatToSearchValue(karat),
              "page": currentPage,
              "limit": _pageLimit,
              ...?stockParam,
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
      final existing = isReady
          ? _karatReadyProducts
          : isOut
              ? _karatOutProducts
              : _karatAllProducts;
      final allFetched = _dedupe(results.expand((list) => list).toList(), existing);

      if (isPagination) {
        existing.addAll(allFetched);
      } else {
        existing.value = allFetched;
      }

      final anyKaratHasMore = results.any((list) => list.length >= _pageLimit);
      if (anyKaratHasMore) {
        currentPage++;
      } else {
        currentHasMore = false;
      }

      if (isReady) {
        _karatReadyHasMore = currentHasMore;
        _karatReadyPage = currentPage;
      } else if (isOut) {
        _karatOutHasMore = currentHasMore;
        _karatOutPage = currentPage;
      } else {
        _karatAllHasMore = currentHasMore;
        _karatAllPage = currentPage;
      }

      state.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      state.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadProductsByKarats error: $e\n$st",
      );
    }
  }

  void loadMoreKaratProducts({String? stockFilter}) {
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';
    final hasMore = isReady ? _karatReadyHasMore : isOut ? _karatOutHasMore : _karatAllHasMore;
    final state = isReady ? _karatReadyState : isOut ? _karatOutState : _karatAllState;
    if (!hasMore || state.value == CurrentAppState.LOADING) return;
    loadProductsByKarats(_currentKarats, isPagination: true, stockFilter: stockFilter);
  }

  Future<void> loadProductsByCategory(String categoryId, {String? stockFilter}) async {
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';

    final state = isReady ? _categoryReadyState : isOut ? _categoryOutState : _categoryAllState;
    final existing = isReady ? _categoryReadyProducts : isOut ? _categoryOutProducts : _categoryAllProducts;

    state.value = CurrentAppState.LOADING;
    existing.clear();

    try {
      final stockParam = _stockQueryParam(stockFilter);
      final response = await httpClient.get(
        ApiUrlConstants.PRODUCTS_GET_ALL,
        queryParameters: {
          "categoryId": categoryId,
          "page": 1,
          "limit": _pageLimit,
          "showReverse": true,
          ...?stockParam,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        existing.value = raw.map((e) => ProductModel.fromJson(e)).toList();
        state.value = CurrentAppState.SUCCESS;
      } else {
        state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      state.value = CurrentAppState.ERROR;
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

  Future<void> loadProductsByMultipleCategories(
    List<String> categoryIds, {
    bool isPagination = false,
    String? stockFilter,
  }) async {
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';

    final state = isReady ? _categoryReadyState : isOut ? _categoryOutState : _categoryAllState;
    final existing = isReady ? _categoryReadyProducts : isOut ? _categoryOutProducts : _categoryAllProducts;

    final hasMore = isReady ? _categoryReadyHasMore : isOut ? _categoryOutHasMore : _categoryAllHasMore;
    if (!hasMore && isPagination) return;
    if (state.value == CurrentAppState.LOADING) return;

    int currentPage = isReady ? _multiCategoryReadyPage : isOut ? _multiCategoryOutPage : _multiCategoryAllPage;
    bool currentHasMore = hasMore;

    if (!isPagination) {
      currentPage = 1;
      currentHasMore = true;
      _currentMultiCategoryIds = List<String>.from(categoryIds);
      if (isReady) {
        _multiCategoryReadyPage = 1;
        _categoryReadyHasMore = true;
        _categoryReadyProducts.clear();
      } else if (isOut) {
        _multiCategoryOutPage = 1;
        _categoryOutHasMore = true;
        _categoryOutProducts.clear();
      } else {
        _multiCategoryAllPage = 1;
        _categoryAllHasMore = true;
        _categoryAllProducts.clear();
      }
    }

    state.value = CurrentAppState.LOADING;

    try {
      final stockParam = _stockQueryParam(stockFilter);
      final futures = categoryIds.map((catId) async {
        try {
          final response = await httpClient.get(
            ApiUrlConstants.PRODUCTS_GET_ALL,
            queryParameters: {
              "categoryId": catId,
              "page": currentPage,
              "limit": _pageLimit,
              "showReverse": true,
              ...?stockParam,
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
      final allFetched = _dedupe(results.expand((list) => list).toList(), existing);

      if (isPagination) {
        existing.addAll(allFetched);
      } else {
        existing.value = allFetched;
      }

      final anyCategoryHasMore = results.any((list) => list.length >= _pageLimit);
      if (anyCategoryHasMore) {
        currentPage++;
      } else {
        currentHasMore = false;
      }

      if (isReady) {
        _categoryReadyHasMore = currentHasMore;
        _multiCategoryReadyPage = currentPage;
      } else if (isOut) {
        _categoryOutHasMore = currentHasMore;
        _multiCategoryOutPage = currentPage;
      } else {
        _categoryAllHasMore = currentHasMore;
        _multiCategoryAllPage = currentPage;
      }

      state.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      state.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadProductsByMultipleCategories error: $e\n$st",
      );
    }
  }

  void loadMoreMultipleCategories({String? stockFilter}) {
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';
    final hasMore = isReady ? _categoryReadyHasMore : isOut ? _categoryOutHasMore : _categoryAllHasMore;
    final state = isReady ? _categoryReadyState : isOut ? _categoryOutState : _categoryAllState;
    if (!hasMore || state.value == CurrentAppState.LOADING) return;
    loadProductsByMultipleCategories(_currentMultiCategoryIds, isPagination: true, stockFilter: stockFilter);
  }

  void loadMoreFilteredProducts({String? stockFilter}) {
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';
    final hasMore = isReady ? _filteredReadyHasMore : isOut ? _filteredOutHasMore : _filteredAllHasMore;
    final state = isReady ? _filteredReadyState : isOut ? _filteredOutState : _filteredAllState;
    final catId = isReady
        ? _currentFilterCategoryIdForReady
        : isOut
            ? _currentFilterCategoryIdForOut
            : _currentFilterCategoryIdForAll;
    final karat = isReady
        ? _currentFilterKaratForReady
        : isOut
            ? _currentFilterKaratForOut
            : _currentFilterKaratForAll;
    if (!hasMore || state.value == CurrentAppState.LOADING) return;
    if (catId == null || karat == null) {
      Logger.warning("SearchProductController", "loadMoreFilteredProducts called before initial load");
      return;
    }
    loadByCategoryWithKaratFilter(catId, karat, isPagination: true, stockFilter: stockFilter);
  }

  Future<void> loadByCategoryWithKaratFilter(
    String categoryId,
    String targetKarat, {
    bool isPagination = false,
    String? stockFilter,
  }) async {
    final isReady = stockFilter == 'ready';
    final isOut = stockFilter == 'out';

    final state = isReady ? _filteredReadyState : isOut ? _filteredOutState : _filteredAllState;
    final existing = isReady ? _filteredReadyProducts : isOut ? _filteredOutProducts : _filteredAllProducts;
    final hasMore = isReady ? _filteredReadyHasMore : isOut ? _filteredOutHasMore : _filteredAllHasMore;

    int currentPage = isReady
        ? _filteredReadyPage
        : isOut
            ? _filteredOutPage
            : _filteredAllPage;
    bool currentHasMore = hasMore;

    if (!hasMore && isPagination) return;
    if (state.value == CurrentAppState.LOADING) return;

    state.value = CurrentAppState.LOADING;

    if (!isPagination) {
      currentPage = 1;
      currentHasMore = true;
      if (isReady) {
        _currentFilterCategoryIdForReady = categoryId;
        _currentFilterKaratForReady = targetKarat;
        _filteredReadyPage = 1;
        _filteredReadyHasMore = true;
        _filteredReadyProducts.clear();
      } else if (isOut) {
        _currentFilterCategoryIdForOut = categoryId;
        _currentFilterKaratForOut = targetKarat;
        _filteredOutPage = 1;
        _filteredOutHasMore = true;
        _filteredOutProducts.clear();
      } else {
        _currentFilterCategoryIdForAll = categoryId;
        _currentFilterKaratForAll = targetKarat;
        _filteredAllPage = 1;
        _filteredAllHasMore = true;
        _filteredAllProducts.clear();
      }
    }

    try {
      final stockParam = _stockQueryParam(stockFilter);
      final response = await httpClient.get(
        ApiUrlConstants.PRODUCTS_GET_ALL,
        queryParameters: {
          "categoryId": categoryId,
          "page": currentPage,
          "limit": _pageLimit,
          "showReverse": true,
          ...?stockParam,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          existing.addAll(_dedupe(allFetched, existing));
        } else {
          existing.value = allFetched;
        }

        if (allFetched.length < _pageLimit) {
          currentHasMore = false;
        } else {
          currentPage++;
        }

        if (isReady) {
          _filteredReadyHasMore = currentHasMore;
          _filteredReadyPage = currentPage;
        } else if (isOut) {
          _filteredOutHasMore = currentHasMore;
          _filteredOutPage = currentPage;
        } else {
          _filteredAllHasMore = currentHasMore;
          _filteredAllPage = currentPage;
        }

        state.value = CurrentAppState.SUCCESS;
      } else {
        state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      state.value = CurrentAppState.ERROR;
      Logger.error(
        "SearchProductController",
        "loadByCategoryWithKaratFilter error: $e\n$st",
      );
    }
  }

  void clearFilteredProducts() {
    _filteredProducts.clear();
    _filteredState.value = CurrentAppState.INITIAL;
    _filteredHasMore = true;
    _filteredReadyProducts.clear();
    _filteredReadyState.value = CurrentAppState.INITIAL;
    _filteredReadyHasMore = true;
    _filteredOutProducts.clear();
    _filteredOutState.value = CurrentAppState.INITIAL;
    _filteredOutHasMore = true;
    _filteredAllProducts.clear();
    _filteredAllState.value = CurrentAppState.INITIAL;
    _filteredAllHasMore = true;
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
    bool? isActive,
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
  }

  void setStockFilter(String value) {
    filterState.setStockFilter(value);
  }

  void clearSearch() {
    _searchQuery.value = '';
    _searchResults.clear();
    _searchState.value = CurrentAppState.INITIAL;
    _searchHasMore = true;
  }

  Future<ProductModel?> searchByBarcode(String barcode) async {
    _searchState.value = CurrentAppState.LOADING;
    _searchQuery.value = '';
    _searchResults.clear();

    try {
      final response = await httpClient.get(
        ApiUrlConstants.PRODUCTS_SEARCH,
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
