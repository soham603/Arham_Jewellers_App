import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class CategoryRepository extends BaseRepository {
  Future<List<dynamic>> fetchCategoryTree() async {
    final response = await dio.get(
      ApiUrlConstants.CATEGORY_GET_ALL,
      queryParameters: {'tree': true, 'full': true},
    );
    final data = response.data['data'];
    if (data is Map && data['results'] is List) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchCategories({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.CATEGORY_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    final data = response.data['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<Map<String, dynamic>> createCategory({
    required FormData data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.CATEGORY_CREATE,
      data: data,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        extra: {'requiresAuth': true},
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editCategory({
    required String id,
    required FormData data,
  }) async {
    final response = await dio.put(
      ApiUrlConstants.categoryEdit(id),
      data: data,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        extra: {'requiresAuth': true},
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteCategory({required String id}) async {
    await dio.delete(
      ApiUrlConstants.categoryDelete(id),
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  Future<Map<String, dynamic>> restoreCategory({required String id}) async {
    final response = await dio.patch(
      ApiUrlConstants.categoryRestore(id),
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data as Map<String, dynamic>;
  }
}
