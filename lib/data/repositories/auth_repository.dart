import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/handsetChangeModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_auth_repository.dart';

class AuthRepository extends BaseRepository implements IAuthRepository {
  @override
  Future<({int statusCode, Map<String, dynamic> data})> loginUser({
    required String phone,
    required String password,
    required String deviceId,
    String? fcmToken,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.USER_LOGIN,
      options: Options(extra: {"requiresAuth": false}),
      data: {
        "phoneNumber": phone,
        "password": password,
        "deviceId": deviceId,
        if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
      },
    );
    return (statusCode: response.statusCode ?? 0, data: response.data as Map<String, dynamic>);
  }

  @override
  Future<({int statusCode, Map<String, dynamic> data})> loginAdmin({
    required String phone,
    required String password,
    required String deviceId,
    String? fcmToken,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_LOGIN,
      options: Options(extra: {"requiresAuth": false}),
      data: {
        "phoneNumber": phone,
        "password": password,
        "deviceId": deviceId,
        if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
      },
    );
    return (statusCode: response.statusCode ?? 0, data: response.data as Map<String, dynamic>);
  }

  @override
  Future<({int statusCode, Map<String, dynamic> data})> registerUser({
    required Map<String, dynamic> userData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.REGISTER,
      options: Options(extra: {"requiresAuth": false}),
      data: userData,
    );
    return (statusCode: response.statusCode ?? 0, data: response.data as Map<String, dynamic>);
  }

  @override
  Future<({int statusCode, Map<String, dynamic> data})> forgotPassword({
    required String phone,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.FORGOT_PASSWORD,
      options: Options(extra: {"requiresAuth": false}),
      data: {"phoneNumber": phone},
    );
    return (statusCode: response.statusCode ?? 0, data: response.data as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResult<HandsetChangeRequestModel>> fetchHandsetRequests({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.DEVICE_CHANGE_REQUEST,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final data = responseData['data'] ?? {};
    final candidates = data is Map
        ? (data['requests'] ?? data['data'] ?? data['results'] ?? [])
        : [];
    final List raw = candidates is List ? candidates : [];
    final pagination = data is Map<String, dynamic> ? parsePagination(data) : (total: raw.length, totalPages: 1, currentPage: 1);

    return PaginatedResult(
      items: raw.map((e) => HandsetChangeRequestModel.fromJson(e)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }

  @override
  Future<({int statusCode, Map<String, dynamic> data})> handleHandsetRequest({
    required String requestId,
    required String action,
    String? rejectionReason,
  }) async {
    final body = <String, dynamic>{
      'requestId': requestId,
      'action': action,
    };
    if (rejectionReason != null) {
      body['rejectionReason'] = rejectionReason;
    }
    final response = await dio.patch(
      ApiUrlConstants.DEVICE_CHANGE_REQUEST_ACTION,
      data: body,
      options: Options(extra: {'requiresAuth': true}),
    );
    return (statusCode: response.statusCode ?? 0, data: response.data as Map<String, dynamic>);
  }
}
