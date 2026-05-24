import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image_picker/image_picker.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CategoryManagerController extends GetxController {
  static CategoryManagerController get instance => Get.find();

  // ── List state ────────────────────────────────────────────────────────────
  final _categories = <CategoryModel>[].obs;
  List<CategoryModel> get categories => _categories;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _total = 0.obs;
  int get total => _total.value;

  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // ── Filters ───────────────────────────────────────────────────────────────
  final _selectedLevel = Rxn<int>();       // null = all
  int? get selectedLevel => _selectedLevel.value;

  final _showDeleted = false.obs;
  bool get showDeleted => _showDeleted.value;

  final _searchName = ''.obs;
  String get searchName => _searchName.value;

  // ── Action states ─────────────────────────────────────────────────────────
  final _actionLoadingId = ''.obs;   // which item is currently doing an action
  String get actionLoadingId => _actionLoadingId.value;

  // ── Image picker ──────────────────────────────────────────────────────────
  final _pickedImage = Rxn<File>();
  File? get pickedImage => _pickedImage.value;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchCategories({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING && !isPagination) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _page = 1;
      _hasMore = true;
    }

    try {
      final response = await httpClient.get(
        "/api/v1/category/get-All",
        queryParameters: {
          "page": _page,
          "limit": _limit,
          "full": true,
          if (_selectedLevel.value != null) "level": _selectedLevel.value,
          if (_searchName.value.isNotEmpty) "name": _searchName.value,
          if (_showDeleted.value) "isDeleted": true,
        },
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final List raw = data['results'] ?? [];
        final fetched = raw.map((e) => CategoryModel.fromJson(e)).toList();

        if (isPagination) {
          _categories.addAll(fetched);
        } else {
          _categories.value = fetched;
        }

        _total.value = data['total'] ?? fetched.length;

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
      Logger.error("CategoryManagerController", "fetch error: $e\n$st");
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;
    await fetchCategories(isPagination: true);
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    await fetchCategories();
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  void setLevelFilter(int? level) {
    _selectedLevel.value = level;
    refresh();
  }

  void setShowDeleted(bool val) {
    _showDeleted.value = val;
    refresh();
  }

  void setNameSearch(String name) {
    _searchName.value = name;
    refresh();
  }

  void clearFilters() {
    _selectedLevel.value = null;
    _showDeleted.value = false;
    _searchName.value = '';
    refresh();
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      _pickedImage.value = File(picked.path);
    }
  }

  void clearPickedImage() => _pickedImage.value = null;

  // ── Edit ──────────────────────────────────────────────────────────────────
  Future<bool> editCategory({
    required String id,
    String? name,
    List<Map<String, String>>? existingImages,
  }) async {
    _actionLoadingId.value = id;

    try {
      final formData = FormData.fromMap({
        if (name != null && name.isNotEmpty) "name": name,
        if (existingImages != null)
          "images": existingImages
              .map((e) => {"url": e["url"], "publicId": e["publicId"]})
              .toList(),
        if (_pickedImage.value != null)
          "image": await MultipartFile.fromFile(_pickedImage.value!.path),
      });

      final response = await httpClient.put(
        "/api/v1/category/edit/$id",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = CategoryModel.fromJson(response.data['data']);
        final idx = _categories.indexWhere((c) => c.id == id);
        if (idx != -1) _categories[idx] = updated;

        _pickedImage.value = null;
        Logger.info("CategoryManagerController", "Category $id updated");
        return true;
      }
    } catch (e) {
      Logger.error("CategoryManagerController", "edit error: $e");
    } finally {
      _actionLoadingId.value = '';
    }
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    _actionLoadingId.value = id;

    try {
      final response = await httpClient.delete(
        "/api/v1/category/delete/$id",
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final idx = _categories.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final cat = _categories[idx];
          _categories[idx] = CategoryModel(
            id: cat.id,
            name: cat.name,
            nameSlug: cat.nameSlug,
            parentId: cat.parentId,
            level: cat.level,
            imageUrl: cat.imageUrl,
            images: cat.images,
            isDeleted: true,
            createdAt: cat.createdAt,
            updatedAt: cat.updatedAt,
          );
        }
        Logger.info("CategoryManagerController", "Category $id soft-deleted");
        return true;
      }
    } catch (e) {
      Logger.error("CategoryManagerController", "delete error: $e");
    } finally {
      _actionLoadingId.value = '';
    }
    return false;
  }

  // ── Restore ───────────────────────────────────────────────────────────────
  Future<bool> restoreCategory(String id) async {
    _actionLoadingId.value = id;

    try {
      final response = await httpClient.patch(
        "/api/v1/category/restore/$id",
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = CategoryModel.fromJson(response.data['data']);
        final idx = _categories.indexWhere((c) => c.id == id);
        if (idx != -1) _categories[idx] = updated;

        Logger.info("CategoryManagerController", "Category $id restored");
        return true;
      }
    } catch (e) {
      Logger.error("CategoryManagerController", "restore error: $e");
    } finally {
      _actionLoadingId.value = '';
    }
    return false;
  }
}