import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminAccessModel.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/userSearchModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_admin_access_repository.dart';

class AdminAccessRepository extends BaseRepository implements IAdminAccessRepository {
  @override
  Future<PaginatedResult<AccessRequestModel>> fetchAccessRequests({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ADMIN_ACCESS_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final data = responseData['data'];
    final Map<String, dynamic> pageData = data is Map<String, dynamic> ? data : {};
    final List raw = pageData['results'] ?? [];
    final pagination = parsePagination(pageData);

    return PaginatedResult(
      items: raw.map((e) => AccessRequestModel.fromJson(e)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }

  @override
  Future<Map<String, dynamic>> handleAccess({
    required Map<String, dynamic> actionData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_ACCESS_HANDLE,
      data: actionData,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  @override
  Future<PaginatedResult<UserSearchModel>> fetchUsers({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ADMIN_ACCESS_GET_ALL_USERS,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final outerData = responseData['data'] ?? {};
    final Map<String, dynamic> innerData =
        outerData is Map<String, dynamic> && outerData['data'] is Map<String, dynamic>
            ? outerData['data']
            : {};
    final List usersRaw = innerData['users'] ?? [];
    final pagination = parsePagination(innerData);

    return PaginatedResult(
      items: usersRaw.map((e) => UserSearchModel.fromJson(e)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }

  @override
  Future<Map<String, dynamic>> toggleUserActivation({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.patch(
      ApiUrlConstants.ADMIN_ACCESS_UPDATE_USER_ACTIVATION,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> createAdmin({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.CREATE_ADMIN,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> toggleRetailer({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_ACCESS_TOGGLE_RETAILER,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> adminResetPassword({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.patch(
      ApiUrlConstants.ADMIN_RESET_PASSWORD,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }
}
