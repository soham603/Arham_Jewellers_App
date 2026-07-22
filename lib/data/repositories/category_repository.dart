import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_category_repository.dart';

class CategoryRepository extends BaseRepository implements ICategoryRepository {
  @override
  Future<List<CategoryModel>> fetchCategoryTree() async {
    final response = await dio.get(
      ApiUrlConstants.CATEGORY_GET_ALL,
      queryParameters: {'tree': true, 'full': true},
    );
    checkApiError(response.data);
    final data = response.data['data'];
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<PaginatedResult<CategoryModel>> fetchCategories({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.CATEGORY_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    checkApiError(response.data);
    requireData(response.data);
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      final List raw = data['results'] ?? [];
      final pagination = parsePagination(data);

      return PaginatedResult(
        items: raw.map((e) => CategoryModel.fromJson(e)).toList(),
        total: pagination.total,
        totalPages: pagination.totalPages,
        currentPage: pagination.currentPage,
      );
    }
    return PaginatedResult(items: [], total: 0, totalPages: 1, currentPage: 1);
  }

  @override
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

  @override
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

  @override
  Future<Map<String, dynamic>> deleteCategory({required String id}) async {
    final response = await dio.delete(
      ApiUrlConstants.categoryDelete(id),
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> restoreCategory({required String id}) async {
    final response = await dio.patch(
      ApiUrlConstants.categoryRestore(id),
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data as Map<String, dynamic>;
  }
}
