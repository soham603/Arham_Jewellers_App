import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/presentation/controllers/search/filter_state.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ProductSearchController extends GetxController {
  static ProductSearchController get instance =>
      Get.isRegistered<ProductSearchController>()
          ? Get.find<ProductSearchController>()
          : Get.put(ProductSearchController());

  static const int _pageLimit = 10;

  late final FilterStateController filterState;

  final _query = ''.obs;
  String get query => _query.value;

  final _products = <ProductModel>[].obs;
  List<ProductModel> get products => _products;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool get isSearching => _query.value.trim().isNotEmpty;

  List<String> get selectedKarats => filterState.selectedKaratsValue;
  List<String> get selectedCategoryIds => filterState.selectedCategoryIdsValue;
  List<String> get selectedCategoryNames => filterState.selectedCategoryNamesValue;
  String get stockFilter => filterState.stockFilterValue;
  bool? get isActiveFilter => filterState.isActiveValue;
  double get weightMin => filterState.weightMinValue;
  double get weightMax => filterState.weightMaxValue;
  List<String> get selectedSizes => filterState.selectedSizesValue;
  double get priceMin => filterState.priceMin;
  double get priceMax => filterState.priceMax;
  bool get hasActiveFilters => filterState.hasActiveFilters;
  int get activeFilterCount => filterState.activeFilterCount;
  double get availableWeightMax => filterState.availableWeightMax;

  List<ProductModel> get allProducts => _products;

  @override
  void onInit() {
    super.onInit();
    filterState = FilterStateController();
    filterState.stockFilter.value = 'all';
    filterState.setProductsProvider(() => allProducts);
  }

  @override
  void onClose() {
    filterState.dispose();
    super.onClose();
  }

  List<ProductModel> _dedupe(List<ProductModel> incoming, List<ProductModel> existing) {
    final existingIds = existing.map((p) => p.id).toSet();
    return incoming.where((p) => existingIds.add(p.id)).toList();
  }

  void search(String query) {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
    _query.value = query.trim();
    _fetchProducts(isPagination: false);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;
    await _fetchProducts(isPagination: true);
  }

  Future<void> _fetchProducts({required bool isPagination}) async {
    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _page = 1;
      _hasMore = true;
      _products.clear();
    }

    try {
      final hasSearch = _query.value.trim().isNotEmpty;
      final endpoint = hasSearch
          ? ApiUrlConstants.PRODUCTS_SEARCH
          : ApiUrlConstants.PRODUCTS_GET_ALL;

      final queryParameters = <String, dynamic>{
        "page": _page,
        "limit": _pageLimit,
      };

      if (hasSearch) {
        queryParameters["search"] = _query.value.trim();
        queryParameters["showAll"] = true;
      } else if (filterState.isActive.value != null) {
        queryParameters["isActive"] = filterState.isActive.value!;
      }

      final response = await httpClient.get(endpoint, queryParameters: queryParameters);

      List<ProductModel> allFetched = [];

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        allFetched = raw.map((e) => ProductModel.fromJson(e)).toList();
      }

      if (filterState.stockFilterValue == 'ready') {
        allFetched = allFetched
            .where((p) => p.grossWeight != null && p.grossWeight! > 0)
            .toList();
      } else if (filterState.stockFilterValue == 'out') {
        allFetched = allFetched
            .where((p) => p.grossWeight == null || p.grossWeight! <= 0)
            .toList();
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
        _products.addAll(_dedupe(allFetched, _products));
      } else {
        _products.value = allFetched;
      }

      if (allFetched.length < _pageLimit) {
        _hasMore = false;
      } else {
        _page++;
      }

      _state.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
    }
  }

  void toggleKaratFilter(String karat) {
    filterState.toggleKaratFilter(karat);
    _fetchProducts(isPagination: false);
  }

  void setStockFilter(String value) {
    filterState.setStockFilter(value);
    _fetchProducts(isPagination: false);
  }

  void setIsActiveFilter(bool? value) {
    filterState.setIsActive(value);
    _fetchProducts(isPagination: false);
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
      isActive: isActive,
    );
    _fetchProducts(isPagination: false);
  }

  void clearAllFilters() {
    filterState.resetFilters();
    _fetchProducts(isPagination: false);
  }

  void clearSearch() {
    _query.value = '';
    _products.clear();
    _state.value = CurrentAppState.INITIAL;
    _page = 1;
    _hasMore = true;
  }

  Future<void> refreshProducts() async {
    await _fetchProducts(isPagination: false);
  }

  Future<ProductModel?> searchByBarcode(String barcode) async {
    _state.value = CurrentAppState.LOADING;
    _query.value = '';
    _products.clear();

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
        _products.value = raw.map((e) => ProductModel.fromJson(e)).toList();
        _state.value = CurrentAppState.SUCCESS;
        return _products.isNotEmpty ? _products.first : null;
      } else {
        _state.value = CurrentAppState.ERROR;
        return null;
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      return null;
    }
  }
}
