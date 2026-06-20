import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/data/repositories/category_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/core/utils/dio_error_helper.dart';
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
  final _categoryRepo = CategoryRepository();

  // ── Level-2 lists per karat 
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

  // ── Latest level-3 categories (for search page) 
  final _latestLevel3Categories = <CategoryModel>[].obs;
  List<CategoryModel> get latestLevel3Categories => _latestLevel3Categories;

  final _latestLevel3State = CurrentAppState.INITIAL.obs;
  CurrentAppState get latestLevel3State => _latestLevel3State.value;

  // ── All level-3 categories (for search results) 
  final _allLevel3Categories = <CategoryModel>[].obs;
  List<CategoryModel> get allLevel3Categories => _allLevel3Categories;

  final _level3KaratMap = <String, String>{}.obs;
  String? getLevel3Karat(String level3Id) => _level3KaratMap[level3Id];

  // ── Expansion state 
  final _expandedCategoryId = RxnString();
  String? get expandedCategoryId => _expandedCategoryId.value;

  // Cache: level2.id → List<CategoryModel> (level 3 children)
  final _level3Cache = <String, List<CategoryModel>>{}.obs;
  Map<String, List<CategoryModel>> get level3Cache => _level3Cache;

  // Loading state for each level-2 → level-3 fetch
  final _level3LoadingIds = <String>{}.obs;
  bool isLevel3Loading(String parentId) => _level3LoadingIds.contains(parentId);

  // ── Selected level-3 category (triggers product section) 
  final _selectedLevel3 = Rxn<CategoryModel>();
  CategoryModel? get selectedLevel3 => _selectedLevel3.value;

  final _showProductSection = false.obs;
  bool get showProductSection => _showProductSection.value;

  // ── Admin 
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

  // ── Karat name → Karat enum mapping 
  static const _karatNameMap = {
    '18K': Karat.k18,
    '20K': Karat.k20,
    '22K': Karat.k22,
  };

  // ── Single API call: fetch full category tree ───
  // Replaces: _getKaratId × 3 + fetchCategoriesForKarat × 3 + _fetchSubcategories per tap
  Future<void>? _treeFetchFuture;
  bool _treeHasFullData = false;
  bool _isInitialized = false;

  // Flat list of all categories from tree, for admin reuse
  List<CategoryModel> _allCategoriesFlat = [];
  List<CategoryModel> get allCategoriesFlat => _allCategoriesFlat;

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
      // Eagerly fetch the category tree on app start
      fetchCategoryTree();
    }
  }

  /// Fetches the full category tree in a single API call.
  /// Always fetches full data (all 3 levels) to avoid redundant refetches.
  Future<void> fetchCategoryTree({bool force = false}) async {
    // If already fetching or have data, return early (unless forced)
    if (!force) {
      if (_treeFetchFuture != null) return _treeFetchFuture!;
      if (_treeHasFullData && _k18Categories.isNotEmpty) return;
    }
    if (force) _treeHasFullData = false;

    _k18State.value = CurrentAppState.LOADING;
    _k20State.value = CurrentAppState.LOADING;
    _k22State.value = CurrentAppState.LOADING;

    _k18Categories.clear();
    _k20Categories.clear();
    _k22Categories.clear();

    _treeFetchFuture = _doFetchCategoryTree();
    await _treeFetchFuture;
    _treeFetchFuture = null;
  }

  bool get hasTreeData => _treeHasFullData;

  Future<void> _doFetchCategoryTree() async {
    try {
      final results = await _categoryRepo.fetchCategoryTree();

      // Build flat list from tree for admin reuse
      final flat = <CategoryModel>[];
      for (final item in results) {
        _flattenTreeNode(item, flat);
      }
      _allCategoriesFlat = flat;

      for (final item in results) {
        final karatCat = CategoryModel.fromJson(item);
        final karat = _karatNameMap[karatCat.name];
        if (karat == null) continue;

        final level2List = <CategoryModel>[];
        final children = karatCat.children;
        if (children != null) {
          for (final level2 in children) {
            level2List.add(level2);

            final level3Children = level2.children;
            if (level3Children != null && level3Children.isNotEmpty) {
              _level3Cache[level2.id] = level3Children;
            }
          }
        }

        _listForKarat(karat).addAll(level2List);
        _stateForKarat(karat).value = CurrentAppState.SUCCESS;
      }

      _populateLatestLevel3FromTree(results);

      _treeHasFullData = true;
    } catch (e, st) {
      _k18State.value = CurrentAppState.ERROR;
      _k20State.value = CurrentAppState.ERROR;
      _k22State.value = CurrentAppState.ERROR;
      Logger.error('CategoryController', 'fetchCategoryTree error: $e\n$st');
    }
  }

  void _flattenTreeNode(dynamic node, List<CategoryModel> flat) {
    flat.add(CategoryModel.fromJson(node));
    final children = node['children'] as List? ?? [];
    for (final child in children) {
      _flattenTreeNode(child, flat);
    }
  }

  // Backward-compatible alias (always fetches full tree)
  Future<void> fetchAllKaratCategories({bool force = false}) => fetchCategoryTree(force: force);

  void _populateLatestLevel3FromTree(List<dynamic> treeResults) {
    final allLevel3 = <CategoryModel>[];
    final karatMap = <String, String>{};

    for (final karatNode in treeResults) {
      final karatName = karatNode['name'] as String? ?? '';
      final children = karatNode['children'] as List? ?? [];
      for (final level2 in children) {
        final level3List = level2['children'] as List? ?? [];
        for (final level3 in level3List) {
          final cat = CategoryModel.fromJson(level3);
          allLevel3.add(cat);
          karatMap[cat.id] = karatName;
        }
      }
    }

    allLevel3.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(0);
      final bDate = b.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    _allLevel3Categories.assignAll(allLevel3);
    _level3KaratMap.assignAll(karatMap);
    _latestLevel3Categories.value = allLevel3.take(7).toList();
    _latestLevel3State.value = CurrentAppState.SUCCESS;
  }

  // ── Fetch latest level-3 categories (for search page) 
  // Now just extracts from tree if available, otherwise falls back to API
  Future<void> fetchLatestLevel3Categories() async {
    if (_latestLevel3State.value == CurrentAppState.LOADING) return;
    if (_latestLevel3Categories.isNotEmpty && _treeHasFullData) return;

    // If tree was already fetched, level-3 data is already populated
    if (_k18State.value == CurrentAppState.SUCCESS) return;

    // Fallback: fetch tree (which includes level-3)
    await fetchCategoryTree();
  }

  // ── Toggle expansion of a level-2 category 
  // Level-3 data is pre-cached from tree; falls back to fetching tree if empty
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
    // If not cached, fetch tree on demand
    if (!_level3Cache.containsKey(id) || (_level3Cache[id]?.isEmpty ?? true)) {
      _level3LoadingIds.add(id);
      await fetchCategoryTree();
      _level3LoadingIds.remove(id);
    }
  }

  // ── Select a level-3 category → show products ───
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

  // ── Admin 
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
      final queryParams = {
        'page': _adminPage,
        'limit': _adminLimit,
        'full': true,
        'level': ?filterLevel,
        if (filterName != null && filterName.isNotEmpty) 'name': filterName,
        'parentId': ?filterParentId,
        if (includeDeleted) 'isDeleted': true,
      };

      final data = await _categoryRepo.fetchCategories(queryParams: queryParams);
      final List raw = data['results'] ?? [];
      final fetched = raw.map((e) => CategoryModel.fromJson(e)).toList();

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

  // ── CRUD 
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
        'description': ?description,
        'parentId': ?parentId,
        'level': ?level,
        if (imageFile != null)
          'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _categoryRepo.createCategory(data: formData);

      final data = response['data'];
      if (data != null) {
        _adminCategoryList.insert(0, CategoryModel.fromJson(data));
      }
      _createState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _createState.value = CurrentAppState.ERROR;
      _error.value = DioErrorHelper.getMessage(e);
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
        'name': ?name,
        'boxName': ?boxName,
        'description': ?description,
        if (imageFile != null)
          'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _categoryRepo.editCategory(id: id, data: formData);

      final updated = response['data'];
      if (updated != null) {
        final model = CategoryModel.fromJson(updated);
        final i = _adminCategoryList.indexWhere((e) => e.id == id);
        if (i != -1) _adminCategoryList[i] = model;
      }
      _editState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _editState.value = CurrentAppState.ERROR;
      _error.value = DioErrorHelper.getMessage(e);
    }
    return false;
  }

  Future<bool> deleteCategory({required String id}) async {
    try {
      _deleteState.value = CurrentAppState.LOADING;
      _error.value = '';

      await _categoryRepo.deleteCategory(id: id);

      _adminCategoryList.removeWhere((e) => e.id == id);
      _deleteState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _deleteState.value = CurrentAppState.ERROR;
      _error.value = DioErrorHelper.getMessage(e);
    }
    return false;
  }

  // ── Helpers 
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
      final data = await _categoryRepo.fetchCategories(queryParams: {
        'level': level,
        'parentId': ?parentId,
        'full': true,
      });
      final List raw = data['results'] ?? [];
      return raw.map((e) => CategoryModel.fromJson(e)).toList();
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
