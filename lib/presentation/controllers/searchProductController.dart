import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
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

  bool get hasActiveFilters =>
      _selectedKarats.isNotEmpty || _selectedCategoryId.value != null;

  int get activeFilterCount =>
      _selectedKarats.length + (_selectedCategoryId.value != null ? 1 : 0);

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

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    loadInitialProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
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
      Logger.error("SearchProductController", "loadInitialProducts error: $e\n$st");
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
      final List<String> searchQueries = [];

      if (_selectedCategoryId.value != null && _selectedCategoryName.isNotEmpty) {
        final cleaned = _selectedCategoryName.value
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim();
        if (_selectedKarats.isNotEmpty) {
          for (final karat in _selectedKarats) {
            searchQueries.add("${_karatToSearchValue(karat)} $cleaned");
          }
        } else if (cleaned.isNotEmpty) {
          searchQueries.add(cleaned);
        }
      } else if (_selectedKarats.isNotEmpty) {
        for (final karat in _selectedKarats) {
          searchQueries.add(_karatToSearchValue(karat));
        }
      }

      List<ProductModel> allFetched = [];

      if (searchQueries.isNotEmpty) {
        for (final q in searchQueries) {
          final response = await httpClient.get(
            "/api/v1/products/search",
            queryParameters: {
              "search": q,
              "page": _filteredInitialPage,
              "limit": _pageLimit,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            allFetched.addAll(raw.map((e) => ProductModel.fromJson(e)).toList());
          }
        }
      } else {
        final response = await httpClient.get(
          "/api/v1/products/get-all",
          queryParameters: {
            "page": _filteredInitialPage,
            "limit": _pageLimit,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          final List raw = data['data'] is List ? data['data'] : [];
          allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
        }
      }

      if (isPagination) {
        _filteredInitialProducts.addAll(allFetched);
      } else {
        _filteredInitialProducts.value = allFetched;
      }

      final expected = searchQueries.isNotEmpty
          ? _pageLimit * searchQueries.length
          : _pageLimit;
      if (allFetched.length < expected) {
        _filteredInitialHasMore = false;
      } else {
        _filteredInitialPage++;
      }

      _filteredInitialState.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _filteredInitialState.value = CurrentAppState.ERROR;
      Logger.error("SearchProductController", "loadFilteredProducts error: $e\n$st");
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
    if (!_searchHasMore || _searchState.value == CurrentAppState.LOADING) return;
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
      List<ProductModel> allFetched = [];

      if (_selectedKarats.isNotEmpty) {
        for (final karat in _selectedKarats) {
          final searchValue = _karatToSearchValue(karat);
          final response = await httpClient.get(
            "/api/v1/products/search",
            queryParameters: {
              "search": "$query $searchValue",
              "page": _searchPage,
              "limit": _pageLimit,
              if (_selectedCategoryId.value != null) "categoryId": _selectedCategoryId.value,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            allFetched.addAll(raw.map((e) => ProductModel.fromJson(e)).toList());
          }
        }
      } else {
        final response = await httpClient.get(
          "/api/v1/products/search",
          queryParameters: {
            "search": query,
            "page": _searchPage,
            "limit": _pageLimit,
            if (_selectedCategoryId.value != null) "categoryId": _selectedCategoryId.value,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          final List raw = data['data'] is List ? data['data'] : [];
          allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
        }
      }

      if (isPagination) {
        _searchResults.addAll(allFetched);
      } else {
        _searchResults.value = allFetched;
      }

      final expected = _selectedKarats.isNotEmpty
          ? _pageLimit * _selectedKarats.length
          : _pageLimit;
      if (allFetched.length < expected) {
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
      case '18K': return '76';
      case '20K': return '84';
      case '22K': return '92';
      default: return karat;
    }
  }

  Future<void> loadProductsByKarats(List<String> karats,
      {bool isPagination = false}) async {
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
      List<ProductModel> allFetched = [];

      for (final karat in karats) {
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
          final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();
          allFetched.addAll(fetched);
        }
      }

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
          "SearchProductController", "loadProductsByKarats error: $e\n$st");
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
        "/api/v1/products/search",
        queryParameters: {
          "categoryId": categoryId,
          "page": 1,
          "limit": _pageLimit,
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
          "SearchProductController", "loadProductsByCategory error: $e\n$st");
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
    if (!_filteredHasMore || _filteredState.value == CurrentAppState.LOADING) return;
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
      final searchValue = _karatToSearchValue(targetKarat);
      Logger.info("CategoryKaratFilter", "Loading categoryId=$categoryId karat=$targetKarat search=$searchValue page=$_filteredPage");

      final response = await httpClient.get(
        "/api/v1/products/search",
        queryParameters: {
          "search": _karatToSearchValue(targetKarat),
          "categoryId": categoryId,
          "page": _filteredPage,
          "limit": _pageLimit,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        Logger.info("CategoryKaratFilter", "Response: ${raw.length} items, status=${response.statusCode}");
        if (raw.isNotEmpty) {
          Logger.info("CategoryKaratFilter", "First item keys: ${(raw.first as Map).keys}");
        }
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _filteredProducts.addAll(fetched);
        } else {
          _filteredProducts.value = fetched;
        }

        if (fetched.length < _pageLimit) {
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
          "SearchProductController", "loadByCategoryWithKaratFilter error: $e\n$st");
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
    _filteredInitialProducts.clear();
    _filteredInitialState.value = CurrentAppState.INITIAL;
    _filteredInitialPage = 1;
    _filteredInitialHasMore = true;
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
        _searchResults.value = raw.map((e) => ProductModel.fromJson(e)).toList();
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