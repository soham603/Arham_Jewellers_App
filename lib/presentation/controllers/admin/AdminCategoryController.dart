import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

Uint8List _compressBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
  final maxEdge = 1200;

  final img.Image resized;
  if (longest > maxEdge) {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxEdge : null,
      height: decoded.height > decoded.width ? maxEdge : null,
      interpolation: img.Interpolation.linear,
    );
  } else {
    resized = decoded;
  }

  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}

class CategoryManagerController extends GetxController {
  static CategoryManagerController get instance => Get.find();

  // ── All categories cache ──────────────────────────────────────────────────
  final _allCategories = <CategoryModel>[].obs;
  List<CategoryModel> get allCategories => _allCategories;

  final _loading = false.obs;
  bool get loading => _loading.value;

  // ── Action states ─────────────────────────────────────────────────────────
  final _actionLoadingId = ''.obs;
  String get actionLoadingId => _actionLoadingId.value;

  // ── Image picker ──────────────────────────────────────────────────────────
  final _pickedImage = Rxn<File>();
  File? get pickedImage => _pickedImage.value;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  // ── Fetch ALL categories in one call ─────────────────────────────────────
  Future<void> fetchAll({bool force = false}) async {
    if (!force && _allCategories.isNotEmpty) return;
    _loading.value = true;
    try {
      final response = await httpClient.get(
        "/api/v1/category/get-All",
        queryParameters: {"full": true},
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List raw = response.data['data']['results'] ?? [];
        _allCategories.value = raw.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      Logger.error("CategoryManagerController", "fetchAll error: $e");
    } finally {
      _loading.value = false;
    }
  }

  // ── Filtered views (client-side) ─────────────────────────────────────────
  List<CategoryModel> byLevel(int level, {String? parentId, bool includeDeleted = true}) {
    return _allCategories.where((c) {
      if (c.level != level) return false;
      if (!includeDeleted && c.isDeleted) return false;
      if (parentId != null && c.parentId != parentId) return false;
      return true;
    }).toList();
  }

  List<CategoryModel> get level1Categories => byLevel(1, includeDeleted: true);

  // Grouped L1: merge duplicates by name, return one entry per unique name
  List<CategoryModel> get level1Grouped {
    final seen = <String, CategoryModel>{};
    for (final c in level1Categories) {
      final key = c.name.trim().toLowerCase();
      if (!seen.containsKey(key)) {
        seen[key] = c;
      }
    }
    return seen.values.toList();
  }

  // Count of L1 parents sharing this group's name
  int level1GroupCount(String name) {
    return level1Categories.where((c) => c.name.trim().toLowerCase() == name.trim().toLowerCase()).length;
  }

  // All L1 parent IDs sharing this group's name
  List<String> level1GroupIds(String name) {
    return level1Categories
        .where((c) => c.name.trim().toLowerCase() == name.trim().toLowerCase())
        .map((c) => c.id)
        .toList();
  }

  // All L2 children from all L1 parents in this group (merged)
  List<CategoryModel> level2ForGroup(String l1Name) {
    final ids = level1GroupIds(l1Name);
    return _allCategories.where((c) {
      if (c.level != 2) return false;
      if (c.parentId == null) return false;
      return ids.contains(c.parentId);
    }).toList();
  }

  List<CategoryModel> level2For(String parentId) => byLevel(2, parentId: parentId, includeDeleted: true);
  List<CategoryModel> get level2All => byLevel(2, includeDeleted: true);

  List<CategoryModel> level3For(String parentId) => byLevel(3, parentId: parentId, includeDeleted: true);
  List<CategoryModel> get level3All => byLevel(3, includeDeleted: true);

  String? parentName(String? parentId) {
    if (parentId == null) return null;
    try {
      return _allCategories.firstWhere((c) => c.id == parentId).name;
    } catch (_) {
      return null;
    }
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) _pickedImage.value = File(picked.path);
  }

  void clearPickedImage() => _pickedImage.value = null;

  static Future<File> _compressImageFile(File file) async {
    final bytes = await file.readAsBytes();
    final compressedBytes = await compute(_compressBytes, bytes);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await compressedFile.writeAsBytes(compressedBytes);
    return compressedFile;
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<String?> createCategory({
    required String name,
    required String boxName,
    String? description,
    String? parentId,
    int? level,
    File? imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'boxName': boxName,
        if (description != null && description.isNotEmpty) 'description': description,
        'parentId': ?parentId,
        'level': ?level,
        if (imageFile != null) 'file': await MultipartFile.fromFile((await _compressImageFile(imageFile)).path),
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
        final created = CategoryModel.fromJson(response.data['data']);
        _allCategories.insert(0, created);
        _pickedImage.value = null;
        Logger.info("CategoryManagerController", "Category created: ${created.name}");
        return null;
      }
      return (response.data is Map) ? (response.data['error']?['message'] ?? response.data['message'] ?? 'Failed to create') : 'Failed to create';
    } catch (e) {
      Logger.error("CategoryManagerController", "create error: $e");
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        return (data is Map) ? (data['error']?['message'] ?? data['message'] ?? 'Something went wrong') : 'Something went wrong';
      }
      return 'Something went wrong';
    }
  }

  // ── Edit ──────────────────────────────────────────────────────────────────
  Future<String?> editCategory({
    required String id,
    String? name,
    String? description,
    String? parentId,
    File? imageFile,
  }) async {
    _actionLoadingId.value = id;

    try {
      final formData = FormData.fromMap({
        if (name != null && name.isNotEmpty) "name": name,
        "description": ?description,
        "parentId": ?parentId,
        if (imageFile != null) "file": await MultipartFile.fromFile((await _compressImageFile(imageFile)).path),
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
        final idx = _allCategories.indexWhere((c) => c.id == id);
        if (idx != -1) _allCategories[idx] = updated;
        _pickedImage.value = null;
        Logger.info("CategoryManagerController", "Category $id updated");
        return null;
      }
      return (response.data is Map) ? (response.data['error']?['message'] ?? response.data['message'] ?? 'Failed to update') : 'Failed to update';
    } catch (e) {
      Logger.error("CategoryManagerController", "edit error: $e");
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        return (data is Map) ? (data['error']?['message'] ?? data['message'] ?? 'Something went wrong') : 'Something went wrong';
      }
      return 'Something went wrong';
    } finally {
      _actionLoadingId.value = '';
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<bool> deleteCategory(String id) async {
    _actionLoadingId.value = id;

    try {
      final response = await httpClient.delete(
        "/api/v1/category/delete/$id",
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final idx = _allCategories.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final cat = _allCategories[idx];
          _allCategories[idx] = CategoryModel(
            id: cat.id, name: cat.name, nameSlug: cat.nameSlug,
            parentId: cat.parentId, level: cat.level,
            imageUrl: cat.imageUrl, images: cat.images,
            isDeleted: true, createdAt: cat.createdAt, updatedAt: cat.updatedAt,
          );
        }
        Logger.info("CategoryManagerController", "Category $id deleted");
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
        final idx = _allCategories.indexWhere((c) => c.id == id);
        if (idx != -1) _allCategories[idx] = updated;
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
