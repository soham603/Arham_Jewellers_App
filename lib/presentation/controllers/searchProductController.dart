import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchProductController extends GetxController {
  static SearchProductController get instance => Get.find();

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
        "/api/v1/products/get-allProducts",
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

  void onSearchChanged(String query) {
    _searchQuery.value = query;

    if (query.trim().isEmpty) {
      clearSearch();
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
      final response = await httpClient.get(
        "/api/v1/products/get-allProducts",
        queryParameters: {
          "search": query,
          "page": _searchPage,
          "limit": _pageLimit,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _searchResults.addAll(fetched);
        } else {
          _searchResults.value = fetched;
        }

        if (fetched.length < _pageLimit) {
          _searchHasMore = false;
        } else {
          _searchPage++;
        }

        _searchState.value = CurrentAppState.SUCCESS;
      } else {
        _searchState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _searchState.value = CurrentAppState.ERROR;
      Logger.error("SearchProductController", "_runSearch error: $e\n$st");
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
      final updated = [
        query,
        ..._recentSearches.where((s) => s.toLowerCase() != query.toLowerCase()),
      ].take(_maxRecentSearches).toList();

      _recentSearches.value = updated;

      final prefs = await SharedPreferences.getInstance();
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