import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_craftsman_repository.dart';

class CraftsmanRepository extends BaseRepository implements ICraftsmanRepository {
  @override
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
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;
    if (query != null && query.isNotEmpty) queryParams['query'] = query;
    if (cityName != null && cityName.isNotEmpty) queryParams['cityName'] = cityName;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (taluka != null && taluka.isNotEmpty) queryParams['taluka'] = taluka;
    if (referenceBy != null && referenceBy.isNotEmpty) queryParams['referenceBy'] = referenceBy;
    if (isActive != null) queryParams['isActive'] = isActive;
    if (includeDeleted != null) queryParams['includeDeleted'] = includeDeleted;

    final response = await dio.get(
      ApiUrlConstants.CRAFTSMAN_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    checkApiError(response.data);
    requireData(response.data);

    final data = response.data['data'];
    if (data is List) {
      return PaginatedResult(
        items: data.map((e) => CraftsmanModel.fromJson(e)).toList(),
        total: data.length,
        totalPages: 1,
        currentPage: 1,
      );
    }
    return parsePaginatedList<CraftsmanModel>(
      response.data,
      listKey: 'craftsmen',
      fromJson: (e) => CraftsmanModel.fromJson(e),
    );
  }

  @override
  Future<Map<String, dynamic>> importCraftsmen({required FormData formData}) async {
    final response = await dio.post(
      ApiUrlConstants.CRAFTSMAN_IMPORT,
      data: formData,
      options: Options(extra: {'requiresAuth': true}),
    );
    checkApiError(response.data);
    requireData(response.data);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> deleteCraftsman({required String id}) async {
    final response = await dio.delete(
      ApiUrlConstants.craftsmanDelete(id),
      options: Options(extra: {'requiresAuth': true}),
    );
    checkApiError(response.data);
    requireData(response.data);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> restoreCraftsman({required String id}) async {
    final response = await dio.patch(
      ApiUrlConstants.craftsmanRestore(id),
      options: Options(extra: {'requiresAuth': true}),
    );
    checkApiError(response.data);
    requireData(response.data);
    return response.data as Map<String, dynamic>;
  }
}
