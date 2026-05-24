import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image_picker/image_picker.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class AdminProductController extends GetxController {
  static AdminProductController get instance => Get.find();

  final _products = <ProductModel>[].obs;
  List<ProductModel> get products => _products;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _total = 0.obs;
  int get total => _total.value;

  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final _isSearchMode = false.obs;
  bool get isSearchMode => _isSearchMode.value;

  final _searchResults = <ProductModel>[].obs;
  List<ProductModel> get searchResults => _searchResults;

  final _searchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get searchState => _searchState.value;

  int _searchPage = 1;
  bool _searchHasMore = true;
  bool get searchHasMore => _searchHasMore;

  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  final _filterKarat = Rxn<String>();
  String? get filterKarat => _filterKarat.value;

  final _filterCategoryId = Rxn<String>();
  String? get filterCategoryId => _filterCategoryId.value;

  final _showInactive = false.obs;
  bool get showInactive => _showInactive.value;

  final _actionLoadingId = ''.obs;
  String get actionLoadingId => _actionLoadingId.value;

  final _pickedImage = Rxn<File>();
  File? get pickedImage => _pickedImage.value;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING && !isPagination) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _page = 1;
      _hasMore = true;
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {"page": _page, "limit": _limit, "showAll": true},
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['data'] is List ? data['data'] : [];
        final fetched = raw.map((e) => ProductModel.fromJson(e)).toList();

        isPagination ? _products.addAll(fetched) : _products.value = fetched;

        _total.value = data['totalCount'] ?? fetched.length;

        if (fetched.length < _limit) {
          _hasMore = false;
        } else {
          _page++;
        }

        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("AdminProductController", "fetchProducts: $e\n$st");
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;
    await fetchProducts(isPagination: true);
  }

  Future<void> refreshProducts() async {
    _page = 1;
    _hasMore = true;
    await fetchProducts();
  }

  Future<void> runSearch({bool isPagination = false}) async {
    final q = _searchQuery.value.trim();
    final hasFilters =
        _filterKarat.value != null || _filterCategoryId.value != null;

    if (q.isEmpty && !hasFilters) {
      exitSearch();
      return;
    }

    if (!isPagination) {
      _isSearchMode.value = true;
      _searchState.value = CurrentAppState.LOADING;
      _searchPage = 1;
      _searchHasMore = true;
      _searchResults.clear();
    }

    try {
      final response = await httpClient.get(
        "/api/v1/products/search",
        queryParameters: {
          if (q.isNotEmpty) "search": q,
          if (_filterKarat.value != null) "karat": _filterKarat.value,
          if (_filterCategoryId.value != null)
            "categoryId": _filterCategoryId.value,
          "page": _searchPage,
          "limit": _limit,
          "showAll": true,
        },
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final raw = data['data'];
        final List list = raw is List ? raw : [];
        final fetched = list.map((e) => ProductModel.fromJson(e)).toList();

        isPagination
            ? _searchResults.addAll(fetched)
            : _searchResults.value = fetched;

        if (fetched.length < _limit) {
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
      Logger.error("AdminProductController", "runSearch: $e\n$st");
    }
  }

  Future<void> loadMoreSearch() async {
    if (!_searchHasMore || _searchState.value == CurrentAppState.LOADING)
      return;
    await runSearch(isPagination: true);
  }

  void setSearch(String q) => _searchQuery.value = q;

  void setKaratFilter(String? karat) {
    _filterKarat.value = karat;
    runSearch();
  }

  void setCategoryFilter(String? id) {
    _filterCategoryId.value = id;
    runSearch();
  }

  void setShowInactive(bool val) {
    _showInactive.value = val;
  }

  void exitSearch() {
    _isSearchMode.value = false;
    _searchQuery.value = '';
    _searchResults.clear();
    _searchState.value = CurrentAppState.INITIAL;
    _searchPage = 1;
    _searchHasMore = true;
    _filterKarat.value = null;
    _filterCategoryId.value = null;
  }

  void clearFilters() {
    _filterKarat.value = null;
    _filterCategoryId.value = null;
    _searchQuery.value = '';
    exitSearch();
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) _pickedImage.value = File(picked.path);
  }

  void clearPickedImage() => _pickedImage.value = null;

  Future<bool> updateProduct({
    required String id,
    String? name,
    String? karat,
    String? categoryId,
    bool? isActive,
    Map<String, dynamic>? rawDataPatch,
    bool deleteCurrentImage = false,
  }) async {
    _actionLoadingId.value = id;

    try {
      final Map<String, dynamic> data = {
        if (name != null && name.trim().isNotEmpty) "name": name.trim(),

        if (karat != null) "karat": karat,

        if (categoryId != null) "categoryId": categoryId,

        if (isActive != null) "isActive": isActive.toString(),

        if (deleteCurrentImage) "deleteImage": "true",

        // IMPORTANT → send valid JSON
        if (rawDataPatch != null) "rawDataPatch": jsonEncode(rawDataPatch),
      };

      if (_pickedImage.value != null) {
        data["image"] = await MultipartFile.fromFile(
          _pickedImage.value!.path,
          filename: _pickedImage.value!.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(data);

      final response = await httpClient.patch(
        "/api/v1/products/update/$id",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = ProductModel.fromJson(response.data["data"]);

        _updateInLists(id, updated);

        _pickedImage.value = null;

        Logger.info(
          "AdminProductController",
          "Product updated successfully → $id",
        );

        return true;
      }

      return false;
    } on DioException catch (e) {
      Logger.error(
        "AdminProductController",
        "updateProduct Dio Error: "
            "${e.response?.data ?? e.message}",
      );
    } catch (e) {
      Logger.error("AdminProductController", "updateProduct Error: $e");
    } finally {
      _actionLoadingId.value = '';
    }

    return false;
  }

  Future<bool> toggleActive(ProductModel product) async {
    return updateProduct(id: product.id, isActive: !product.isActive);
  }

  void _updateInLists(String id, ProductModel updated) {
    final i = _products.indexWhere((p) => p.id == id);
    if (i != -1) _products[i] = updated;

    final j = _searchResults.indexWhere((p) => p.id == id);
    if (j != -1) _searchResults[j] = updated;
  }

  List<ProductModel> get displayList =>
      _isSearchMode.value ? _searchResults : _products;
}
