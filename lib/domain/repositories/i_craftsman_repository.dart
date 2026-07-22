import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';

abstract class ICraftsmanRepository {
  Future<PaginatedResult<CraftsmanModel>> fetchCraftsmen({
    int? page,
    int? limit,
    String? query,
    String? cityName,
    String? state,
    String? taluka,
    String? referenceBy,
    bool? isActive,
    bool? includeDeleted,
  });
  Future<Map<String, dynamic>> importCraftsmen({required FormData formData});
  Future<Map<String, dynamic>> deleteCraftsman({required String id});
  Future<Map<String, dynamic>> restoreCraftsman({required String id});
}
