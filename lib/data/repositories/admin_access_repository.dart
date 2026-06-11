import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class AdminAccessRepository extends BaseRepository {
  Future<Map<String, dynamic>> fetchAccessRequests({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ADMIN_ACCESS_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

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

  Future<Map<String, dynamic>> fetchUsers({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ADMIN_ACCESS_GET_ALL_USERS,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> toggleUserActivation({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.post(
      '/api/v1/admin-access/update-user-activation',
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> toggleStaff({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_ACCESS_TOGGLE_STAFF,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

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

  Future<Map<String, dynamic>> adminResetPassword({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_RESET_PASSWORD,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }
}
