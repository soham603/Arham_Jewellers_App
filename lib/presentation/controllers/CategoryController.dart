import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

enum Karat { k18, k20, k22 }

extension KaratExtension on Karat {
  String get slug {
    switch (this) {
      case Karat.k18:
        return '18k';
      case Karat.k20:
        return '20k';
      case Karat.k22:
        return '22k';
    }
  }

  String get displayName {
    switch (this) {
      case Karat.k18:
        return '18K';
      case Karat.k20:
        return '20K';
      case Karat.k22:
        return '22K';
    }
  }
}

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  // ── Level-2 lists per karat ───────────────────────────────────────────────
  final _k18Categories = <CategoryModel>[].obs;
  final _k20Categories = <CategoryModel>[].obs;
  final _k22Categories = <CategoryModel>[].obs;

  List<CategoryModel> get k18Categories => _k18Categories;
  List<CategoryModel> get k20Categories => _k20Categories;
  List<CategoryModel> get k22Categories => _k22Categories;

  final _k18State = CurrentAppState.INITIAL.obs;
  final _k20State = CurrentAppState.INITIAL.obs;
  final _k22State = CurrentAppState.INITIAL.obs;

  CurrentAppState get k18State => _k18State.value;
  CurrentAppState get k20State => _k20State.value;
  CurrentAppState get k22State => _k22State.value;

  // ── Latest level-3 categories (for search page) ─────────────────────────
  final _latestLevel3Categories = <CategoryModel>[].obs;
  List<CategoryModel> get latestLevel3Categories => _latestLevel3Categories;

  final _latestLevel3State = CurrentAppState.INITIAL.obs;
  CurrentAppState get latestLevel3State => _latestLevel3State.value;

  // ── Expansion state ───────────────────────────────────────────────────────
  final _expandedCategoryId = RxnString();
  String? get expandedCategoryId => _expandedCategoryId.value;

  // Cache: level2.id → List<CategoryModel> (level 3 children)
  final _level3Cache = <String, List<CategoryModel>>{}.obs;
  Map<String, List<CategoryModel>> get level3Cache => _level3Cache;

  // Loading state for each level-2 → level-3 fetch
  final _level3LoadingIds = <String>{}.obs;
  bool isLevel3Loading(String parentId) => _level3LoadingIds.contains(parentId);

  // ── Selected level-3 category (triggers product section) ─────────────────
  final _selectedLevel3 = Rxn<CategoryModel>();
  CategoryModel? get selectedLevel3 => _selectedLevel3.value;

  final _showProductSection = false.obs;
  bool get showProductSection => _showProductSection.value;

  // ── Admin ─────────────────────────────────────────────────────────────────
  final _adminCategoryList = <CategoryModel>[].obs;
  List<CategoryModel> get adminCategoryList => _adminCategoryList;

  final _adminState = CurrentAppState.INITIAL.obs;
  CurrentAppState get adminState => _adminState.value;

  final _adminTotal = 0.obs;
  int get adminTotal => _adminTotal.value;

  int _adminPage = 1;
  final int _adminLimit = 20;
  bool adminHasMore = true;

  final _createState = CurrentAppState.INITIAL.obs;
  CurrentAppState get createState => _createState.value;

  final _editState = CurrentAppState.INITIAL.obs;
  CurrentAppState get editState => _editState.value;

  final _deleteState = CurrentAppState.INITIAL.obs;
  CurrentAppState get deleteState => _deleteState.value;

  final _error = ''.obs;
  String get error => _error.value;

  // ── Karat name → Karat enum mapping ─────────────────────────────────────
  static const _karatNameMap = {
    '18K': Karat.k18,
    '20K': Karat.k20,
    '22K': Karat.k22,
  };

  // ── Single API call: fetch full category tree ────────────────────────────
  // Replaces: _getKaratId × 3 + fetchCategoriesForKarat × 3 + _fetchSubcategories per tap
  Future<void>? _treeFetchFuture;
  bool _treeHasFullData = false;

  /// Fetches the full category tree in a single API call.
  ///
  /// When [full] is `true` (default), returns all 3 levels (Karat → Collection → Style).
  /// When [full] is `false`, returns only Level 1 & Level 2 (useful for initial load).
  Future<void> fetchCategoryTree({bool full = true}) async {
    // If already fetching with the same or greater scope, return the in-progress future
    if (_treeFetchFuture != null) {
      // If we already have full data or are fetching full, just wait
      if (_treeHasFullData || full) return _treeFetchFuture!;
      // If requesting full but current fetch is partial, wait and re-fetch
      await _treeFetchFuture;
      if (_treeHasFullData) return;
    }

    _k18State.value = CurrentAppState.LOADING;
    _k20State.value = CurrentAppState.LOADING;
    _k22State.value = CurrentAppState.LOADING;

    _k18Categories.clear();
    _k20Categories.clear();
    _k22Categories.clear();

    _treeFetchFuture = _doFetchCategoryTree(full: full);
    await _treeFetchFuture;
    _treeFetchFuture = null;
  }

  Future<void> _doFetchCategoryTree({bool full = true}) async {

    try {
      final response = await httpClient.get(
        '/api/v1/category/get-All',
        queryParameters: {'tree': true, 'full': full},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map && data['results'] is List) {
          final results = data['results'] as List;

          for (final item in results) {
            final karatCat = CategoryModel.fromJson(item);
            final karat = _karatNameMap[karatCat.name];
            if (karat == null) continue;

            final level2List = <CategoryModel>[];
            final children = karatCat.children;
            if (children != null) {
              for (final level2 in children) {
                level2List.add(level2);

                // Pre-cache level-3 children
                final level3Children = level2.children;
                if (level3Children != null && level3Children.isNotEmpty) {
                  _level3Cache[level2.id] = level3Children;
                }
              }
            }

            _listForKarat(karat).addAll(level2List);
            _stateForKarat(karat).value = CurrentAppState.SUCCESS;
          }

          // Populate latest level-3 categories from tree
          _populateLatestLevel3FromTree(results);

          _treeHasFullData = full;
          return;
        }
      }

      _k18State.value = CurrentAppState.ERROR;
      _k20State.value = CurrentAppState.ERROR;
      _k22State.value = CurrentAppState.ERROR;
    } catch (e, st) {
      _k18State.value = CurrentAppState.ERROR;
      _k20State.value = CurrentAppState.ERROR;
      _k22State.value = CurrentAppState.ERROR;
      Logger.error('CategoryController', 'fetchCategoryTree error: $e\n$st');
    }
  }

  // Backward-compatible alias (always fetches full tree)
  Future<void> fetchAllKaratCategories() => fetchCategoryTree(full: true);

  void _populateLatestLevel3FromTree(List<dynamic> treeResults) {
    final allLevel3 = <CategoryModel>[];
    for (final karatNode in treeResults) {
      final children = karatNode['children'] as List? ?? [];
      for (final level2 in children) {
        final level3List = level2['children'] as List? ?? [];
        for (final level3 in level3List) {
          allLevel3.add(CategoryModel.fromJson(level3));
        }
      }
    }

    allLevel3.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(0);
      final bDate = b.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    _latestLevel3Categories.value = allLevel3.take(7).toList();
    _latestLevel3State.value = CurrentAppState.SUCCESS;
  }

  // ── Fetch latest level-3 categories (for search page) ───────────────────
  // Now just extracts from tree if available, otherwise falls back to API
  Future<void> fetchLatestLevel3Categories() async {
    if (_latestLevel3State.value == CurrentAppState.LOADING) return;
    if (_latestLevel3Categories.isNotEmpty && _treeHasFullData) return;

    // If tree was fetched but without full data, fetch full tree
    if (_k18State.value == CurrentAppState.SUCCESS && !_treeHasFullData) {
      await fetchCategoryTree(full: true);
      return;
    }

    // If tree was already fetched with full data, level-3 data is already populated
    if (_k18State.value == CurrentAppState.SUCCESS) return;

    // Fallback: fetch tree (which includes level-3)
    await fetchCategoryTree(full: true);
  }

  // ── Toggle expansion of a level-2 category ───────────────────────────────
  // Level-3 data is pre-cached from tree; falls back to fetching full tree if empty
  Future<void> toggleExpand(CategoryModel category) async {
    final id = category.id;

    if (_expandedCategoryId.value == id) {
      _expandedCategoryId.value = null;
      _selectedLevel3.value = null;
      _showProductSection.value = false;
      return;
    }

    _expandedCategoryId.value = id;
    _selectedLevel3.value = null;
    _showProductSection.value = false;

    // Level-3 data is already cached from tree response
    // If not cached (e.g., initial load used full=false), fetch full tree on demand
    if (!_level3Cache.containsKey(id) || (_level3Cache[id]?.isEmpty ?? true)) {
      if (!_treeHasFullData) {
        _level3LoadingIds.add(id);
        await fetchCategoryTree(full: true);
        _level3LoadingIds.remove(id);
      }
    }
  }

  // ── Select a level-3 category → show products ────────────────────────────
  void selectLevel3Category(CategoryModel category) {
    _selectedLevel3.value = category;
    _showProductSection.value = true;
    SearchProductController.instance.loadProductsByCategory(category.id);
  }

  void clearSelectedLevel3() {
    _selectedLevel3.value = null;
    _showProductSection.value = false;
    SearchProductController.instance.clearCategoryProducts();
  }

  // ── Admin ─────────────────────────────────────────────────────────────────
  Future<void> fetchAdminCategories({
    bool isPagination = false,
    int? filterLevel,
    String? filterName,
    String? filterParentId,
    bool includeDeleted = false,
  }) async {
    if (_adminState.value == CurrentAppState.LOADING && !isPagination) return;

    if (!isPagination) {
      _adminState.value = CurrentAppState.LOADING;
      _adminPage = 1;
      adminHasMore = true;
    }

    try {
      final response = await httpClient.get(
        '/api/v1/category/get-All',
        queryParameters: {
          'page': _adminPage,
          'limit': _adminLimit,
          'full': true,
          if (filterLevel != null) 'level': filterLevel,
          if (filterName != null && filterName.isNotEmpty) 'name': filterName,
          if (filterParentId != null) 'parentId': filterParentId,
          if (includeDeleted) 'isDeleted': true,
        },
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map && data['results'] is List) {
          final fetched = (data['results'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList();

          if (isPagination) {
            _adminCategoryList.addAll(fetched);
          } else {
            _adminCategoryList.value = fetched;
          }

          _adminTotal.value = data['total'] ?? fetched.length;

          if (fetched.length < _adminLimit) {
            adminHasMore = false;
          } else {
            _adminPage++;
          }

          _adminState.value = CurrentAppState.SUCCESS;
        } else {
          _adminState.value = CurrentAppState.ERROR;
        }
      } else {
        _adminState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _adminState.value = CurrentAppState.ERROR;
      Logger.error('CategoryController', 'fetchAdminCategories error: $e\n$st');
    }
  }

  Future<void> loadMoreAdminCategories({int? filterLevel}) async {
    if (!adminHasMore || _adminState.value == CurrentAppState.LOADING) return;
    await fetchAdminCategories(isPagination: true, filterLevel: filterLevel);
  }

  Future<void> refreshAdminCategories({int? filterLevel}) async {
    _adminPage = 1;
    adminHasMore = true;
    await fetchAdminCategories(isPagination: false, filterLevel: filterLevel);
  }

  Future<List<CategoryModel>> fetchLevel1Categories() async {
    return _fetchLevelFlat(level: 1);
  }

  Future<List<CategoryModel>> fetchLevel2Categories({String? parentId}) async {
    return _fetchLevelFlat(level: 2, parentId: parentId);
  }

  Future<List<CategoryModel>> fetchLevel3Categories({String? parentId}) async {
    return _fetchLevelFlat(level: 3, parentId: parentId);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<bool> createCategory({
    required String name,
    required String boxName,
    String? description,
    String? parentId,
    int? level,
    File? imageFile,
  }) async {
    try {
      _createState.value = CurrentAppState.LOADING;
      _error.value = '';

      final formData = FormData.fromMap({
        'name': name,
        'boxName': boxName,
        if (description != null) 'description': description,
        if (parentId != null) 'parentId': parentId,
        if (level != null) 'level': level,
        if (imageFile != null)
          'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await httpClient.post(
        '/api/v1/category/create',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          extra: {'requiresAuth': true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data != null) {
          _adminCategoryList.insert(0, CategoryModel.fromJson(data));
        }
        _createState.value = CurrentAppState.SUCCESS;
        return true;
      } else {
        _createState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? 'Create failed';
      }
    } catch (e) {
      _createState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
    return false;
  }

  Future<bool> editCategory({
    required String id,
    String? name,
    String? boxName,
    String? description,
    File? imageFile,
  }) async {
    try {
      _editState.value = CurrentAppState.LOADING;
      _error.value = '';

      final formData = FormData.fromMap({
        if (name != null) 'name': name,
        if (boxName != null) 'boxName': boxName,
        if (description != null) 'description': description,
        if (imageFile != null)
          'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await httpClient.put(
        '/api/v1/category/edit/$id',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          extra: {'requiresAuth': true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = response.data['data'];
        if (updated != null) {
          final model = CategoryModel.fromJson(updated);
          final i = _adminCategoryList.indexWhere((e) => e.id == id);
          if (i != -1) _adminCategoryList[i] = model;
        }
        _editState.value = CurrentAppState.SUCCESS;
        return true;
      } else {
        _editState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? 'Update failed';
      }
    } catch (e) {
      _editState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
    return false;
  }

  Future<bool> deleteCategory({required String id}) async {
    try {
      _deleteState.value = CurrentAppState.LOADING;
      _error.value = '';

      final response = await httpClient.delete(
        '/api/v1/category/delete/$id',
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _adminCategoryList.removeWhere((e) => e.id == id);
        _deleteState.value = CurrentAppState.SUCCESS;
        return true;
      } else {
        _deleteState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? 'Delete failed';
      }
    } catch (e) {
      _deleteState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<List<CategoryModel>> _fetchLevelFlat({
    required int level,
    String? parentId,
  }) async {
    // Try to use cached tree data for level-3 (most common admin query)
    if (level == 3 && parentId != null && _treeHasFullData) {
      final cached = _level3Cache[parentId];
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final response = await httpClient.get(
        '/api/v1/category/get-All',
        queryParameters: {
          'level': level,
          if (parentId != null) 'parentId': parentId,
          'full': true,
        },
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map && data['results'] is List) {
          return (data['results'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      Logger.error('CategoryController', '_fetchLevelFlat error: $e');
    }
    return [];
  }

  Rx<CurrentAppState> _stateForKarat(Karat karat) {
    switch (karat) {
      case Karat.k18:
        return _k18State;
      case Karat.k20:
        return _k20State;
      case Karat.k22:
        return _k22State;
    }
  }

  RxList<CategoryModel> _listForKarat(Karat karat) {
    switch (karat) {
      case Karat.k18:
        return _k18Categories;
      case Karat.k20:
        return _k20Categories;
      case Karat.k22:
        return _k22Categories;
    }
  }
}
