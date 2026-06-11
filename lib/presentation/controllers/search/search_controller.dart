import 'dart:async';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class SearchFetchController extends GetxController {
  static const int _pageLimit = 10;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _products = <ProductModel>[].obs;
  List<ProductModel> get products => _products;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _currentQuery = '';
  String? _currentCategoryId;
  String _fetchType = 'initial';

  Future<void> loadProducts({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      _fetchType = 'initial';
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {
          "page": _currentPage,
          "limit": _pageLimit,
          "showReverse": true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _products.addAll(fetched);
        } else {
          _products.value = fetched;
        }

        if (fetched.length < _pageLimit) {
          _hasMore = false;
        } else {
          _currentPage++;
        }

        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("SearchFetchController", "loadProducts error: $e\n$st");
    }
  }

  Future<void> searchProducts(String query, {bool isPagination = false}) async {
    if (_state.value == CurrentAppState.LOADING && !isPagination) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      _currentQuery = query;
      _fetchType = 'search';
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/search",
        queryParameters: {
          "search": query,
          "page": _currentPage,
          "limit": _pageLimit,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _products.addAll(fetched);
        } else {
          _products.value = fetched;
        }

        if (fetched.length < _pageLimit) {
          _hasMore = false;
        } else {
          _currentPage++;
        }

        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("SearchFetchController", "searchProducts error: $e\n$st");
    }
  }

  Future<void> loadByCategory(String categoryId, {bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      _currentCategoryId = categoryId;
      _fetchType = 'category';
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {
          "categoryId": categoryId,
          "page": _currentPage,
          "limit": _pageLimit,
          "showReverse": true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        if (isPagination) {
          _products.addAll(fetched);
        } else {
          _products.value = fetched;
        }

        if (fetched.length < _pageLimit) {
          _hasMore = false;
        } else {
          _currentPage++;
        }

        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("SearchFetchController", "loadByCategory error: $e\n$st");
    }
  }

  Future<void> loadByBarcode(String barcode) async {
    _state.value = CurrentAppState.LOADING;
    _products.clear();

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
        _products.value = raw.map((e) => ProductModel.fromJson(e)).toList();
        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("SearchFetchController", "loadByBarcode error: $e\n$st");
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;

    switch (_fetchType) {
      case 'search':
        await searchProducts(_currentQuery, isPagination: true);
        break;
      case 'category':
        if (_currentCategoryId != null) {
          await loadByCategory(_currentCategoryId!, isPagination: true);
        }
        break;
      default:
        await loadProducts(isPagination: true);
    }
  }

  void refreshProducts() {
    _currentPage = 1;
    _hasMore = true;

    switch (_fetchType) {
      case 'search':
        searchProducts(_currentQuery);
        break;
      case 'category':
        if (_currentCategoryId != null) {
          loadByCategory(_currentCategoryId!);
        }
        break;
      default:
        loadProducts();
    }
  }

  void clear() {
    _products.clear();
    _state.value = CurrentAppState.INITIAL;
    _currentPage = 1;
    _hasMore = true;

    _currentQuery = '';
    _currentCategoryId = null;
    _fetchType = 'initial';
  }
}
