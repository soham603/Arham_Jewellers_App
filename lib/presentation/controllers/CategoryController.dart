import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _total = 0.obs;
  int get total => _total.value;

  int page = 1;
  int limit = 10;
  bool hasMore = true;
  bool isPaginatedCall = false;

    final _categoryList = <CategoryModel>[].obs;
  List<CategoryModel> get categoryList => _categoryList;

  final _createState = CurrentAppState.INITIAL.obs;
  CurrentAppState get createState => _createState.value;

  final _editState = CurrentAppState.INITIAL.obs;
  CurrentAppState get editState => _editState.value;

  final _deleteState = CurrentAppState.INITIAL.obs;
  CurrentAppState get deleteState => _deleteState.value;

  final _error = "".obs;
  String get error => _error.value;

  Future<void> getAllCategories({
    bool isPagination = false,
  }) async {
    if (_state.value == CurrentAppState.LOADING && !isPagination) return;

    try {
      if (!isPagination) {
        _state.value = CurrentAppState.LOADING;
        page = 1;
        hasMore = true;
      }

      final response = await httpClient.get(
        "/api/v1/category/get-All",
        queryParameters: isPagination
            ? {
                "page": page,
                "limit": limit,
              }
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['results'] is List) {
          final fetched = (data['results'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList();

          if (isPagination) {
            _categoryList.addAll(fetched);
          } else {
            _categoryList.value = fetched;
          }

          _total.value = data['total'] ?? fetched.length;
          isPaginatedCall = data['paginated'] ?? false;

          if (fetched.length < limit) {
            hasMore = false;
          } else {
            page++;
          }

          _state.value = CurrentAppState.SUCCESS;

          Logger.info(
            "CategoryController",
            "Fetched ${fetched.length} categories (Total: $_total)",
          );
        } else {
          _state.value = CurrentAppState.ERROR;
          Logger.error("CategoryController", "Invalid response format");
        }
      } else {
        _state.value = CurrentAppState.ERROR;
        Logger.error(
          "CategoryController",
          "HTTP error: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      Logger.error("CategoryController", "Error: $e\n$st");
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _state.value == CurrentAppState.LOADING) return;

    await getAllCategories(isPagination: true);
  }

  Future<void> refreshCategories() async {
    page = 1;
    hasMore = true;
    await getAllCategories(isPagination: false);
  }

  Future<bool> createCategory({
    required String name,
    required String boxName,
    String? description,
    File? imageFile,
  }) async {
    try {
      _createState.value = CurrentAppState.LOADING;
      _error.value = "";

      final formData = FormData.fromMap({
        "name": name,
        "boxName": boxName,
        "description": description ?? "",
        if (imageFile != null)
          "file": await MultipartFile.fromFile(imageFile.path),
      });

      final response = await httpClient.post(
        "/api/v1/category/create",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        if (data != null) {
          final newCategory = CategoryModel.fromJson(data);

          _categoryList.insert(0, newCategory);
        }

        _createState.value = CurrentAppState.SUCCESS;

        Logger.info("AdminCategory", "Category created");

        return true;
      } else {
        _createState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? "Create failed";
      }
    } catch (e) {
      _createState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error("AdminCategory", "Create error: $e");
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
      _error.value = "";

      final formData = FormData.fromMap({
        if (name != null) "name": name,
        if (boxName != null) "boxName": boxName,
        if (description != null) "description": description,
        if (imageFile != null)
          "file": await MultipartFile.fromFile(imageFile.path),
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
        final updatedData = response.data['data'];

        if (updatedData != null) {
          final updatedCategory = CategoryModel.fromJson(updatedData);

          final index = _categoryList.indexWhere((e) => e.id == id);

          if (index != -1) {
            _categoryList[index] = updatedCategory;
          }
        }

        _editState.value = CurrentAppState.SUCCESS;

        Logger.info("AdminCategory", "Category updated");

        return true;
      } else {
        _editState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? "Update failed";
      }
    } catch (e) {
      _editState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error("AdminCategory", "Edit error: $e");
    }

    return false;
  }

  Future<bool> deleteCategory({
    required String id,
  }) async {
    try {
      _deleteState.value = CurrentAppState.LOADING;
      _error.value = "";

      final response = await httpClient.delete(
        "/api/v1/category/delete/$id",
        options: Options(
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        _categoryList.removeWhere((e) => e.id == id);

        _deleteState.value = CurrentAppState.SUCCESS;

        Logger.info("AdminCategory", "Category deleted");

        return true;
      } else {
        _deleteState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? "Delete failed";
      }
    } catch (e) {
      _deleteState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error("AdminCategory", "Delete error: $e");
    }

    return false;
  }
}