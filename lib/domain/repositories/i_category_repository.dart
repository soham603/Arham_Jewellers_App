import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';

abstract class ICategoryRepository {
  Future<List<CategoryModel>> fetchCategoryTree();
  Future<PaginatedResult<CategoryModel>> fetchCategories({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> createCategory({
    required FormData data,
  });
  Future<Map<String, dynamic>> editCategory({
    required String id,
    required FormData data,
  });
  Future<Map<String, dynamic>> deleteCategory({required String id});
  Future<Map<String, dynamic>> restoreCategory({required String id});
}
