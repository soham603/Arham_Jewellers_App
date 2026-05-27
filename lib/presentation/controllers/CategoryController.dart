import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
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

  // ── Expansion state ───────────────────────────────────────────────────────
  // Which level-2 category is currently expanded (shows its level-3 children)
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

  // Whether the product section should be visible
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

  // ── Public: fetch level-2 for a karat ────────────────────────────────────
  Future<void> fetchCategoriesForKarat(Karat karat) async {
    final stateObs = _stateForKarat(karat);
    if (stateObs.value == CurrentAppState.LOADING) return;

    stateObs.value = CurrentAppState.LOADING;

    try {
      final karatId = await _getKaratId(karat);
      if (karatId == null) {
        stateObs.value = CurrentAppState.ERROR;
        Logger.error(
            'CategoryController', 'Karat not found: ${karat.displayName}');
        return;
      }

      final response = await httpClient.get(
        '/api/v1/category/get-All',
        queryParameters: {'parentId': karatId, 'level': 2},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map && data['results'] is List) {
          final fetched = (data['results'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList();
          _listForKarat(karat).value = fetched;
          stateObs.value = CurrentAppState.SUCCESS;
        } else {
          stateObs.value = CurrentAppState.ERROR;
        }
      } else {
        stateObs.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      stateObs.value = CurrentAppState.ERROR;
      Logger.error(
          'CategoryController', 'fetchCategoriesForKarat error: $e\n$st');
    }
  }

  Future<void> fetchAllKaratCategories() async {
    await Future.wait([
      fetchCategoriesForKarat(Karat.k18),
      fetchCategoriesForKarat(Karat.k20),
      fetchCategoriesForKarat(Karat.k22),
    ]);
  }

  // ── Toggle expansion of a level-2 category ───────────────────────────────
  // If the same card is tapped again → collapse.
  // Otherwise → expand and fetch level-3 children (cached after first load).
  Future<void> toggleExpand(CategoryModel category) async {
    final id = category.id;

    // Tapping the already-expanded one → collapse
    if (_expandedCategoryId.value == id) {
      _expandedCategoryId.value = null;
      _selectedLevel3.value = null;
      _showProductSection.value = false;
      return;
    }

    _expandedCategoryId.value = id;
    _selectedLevel3.value = null;
    _showProductSection.value = false;

    // Already cached → nothing to fetch
    if (_level3Cache.containsKey(id)) return;

    // Fetch level-3 children
    _level3LoadingIds.add(id);
    try {
      final children = await _fetchSubcategories(id);
      _level3Cache[id] = children;
    } finally {
      _level3LoadingIds.remove(id);
    }
  }

  // ── Select a level-3 category → show products ────────────────────────────
  void selectLevel3Category(CategoryModel category) {
    _selectedLevel3.value = category;
    _showProductSection.value = true;
    // TODO: trigger product fetch here using category.id
    // e.g. productController.fetchProductsByCategory(category.id);
  }

  void clearSelectedLevel3() {
    _selectedLevel3.value = null;
    _showProductSection.value = false;
  }

  // ── Fetch level-3 under a level-2 ────────────────────────────────────────
  Future<List<CategoryModel>> _fetchSubcategories(String parentId) async {
    try {
      final response = await httpClient.get(
        '/api/v1/category/get-All',
        queryParameters: {'parentId': parentId, 'level': 3},
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
      Logger.error('CategoryController', 'fetchSubcategories error: $e');
    }
    return [];
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

  Future<List<CategoryModel>> fetchLevel2Categories(
      {String? parentId}) async {
    return _fetchLevelFlat(level: 2, parentId: parentId);
  }

  Future<List<CategoryModel>> fetchLevel3Categories(
      {String? parentId}) async {
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
  final Map<Karat, String> _karatIdCache = {};

  Future<String?> _getKaratId(Karat karat) async {
    if (_karatIdCache.containsKey(karat)) return _karatIdCache[karat];

    try {
      final response = await httpClient.get(
        '/api/v1/category/get-All',
        queryParameters: {'level': 1, 'name': karat.displayName},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map && data['results'] is List) {
          final list = data['results'] as List;
          if (list.isNotEmpty) {
            final id = list.first['id'] as String;
            _karatIdCache[karat] = id;
            return id;
          }
        }
      }
    } catch (e) {
      Logger.error('CategoryController', '_getKaratId error: $e');
    }
    return null;
  }

  Future<List<CategoryModel>> _fetchLevelFlat({
    required int level,
    String? parentId,
  }) async {
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