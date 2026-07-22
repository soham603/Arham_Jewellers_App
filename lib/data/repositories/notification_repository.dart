import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/sent_notification_model.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_notification_repository.dart';

class NotificationRepository extends BaseRepository implements INotificationRepository {
  @override
  Future<PaginatedResult<NotificationModel>> getAllNotifications({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.NOTIFICATION_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final nestedData = responseData['data'];

    List<dynamic> rawItems;
    Map<String, dynamic> paginationData = {};
    if (nestedData is Map<String, dynamic>) {
      rawItems = nestedData['notifications'] ?? nestedData['data'] ?? [];
      paginationData = nestedData;
    } else {
      rawItems = responseData['notifications'] ?? [];
      paginationData = responseData;
    }

    final pagination = parsePagination(paginationData);

    return PaginatedResult(
      items: rawItems.map((json) => NotificationModel.fromJson(json)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }

  @override
  Future<Map<String, dynamic>> markNotificationsAsRead({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.patch(
      ApiUrlConstants.NOTIFICATION_ACTION,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  @override
  Future<void> updateFcmToken({
    required Map<String, dynamic> data,
  }) async {
    await dio.post(
      ApiUrlConstants.UPDATE_FCM_TOKEN,
      data: data,
    );
  }

  @override
  Future<Map<String, dynamic>> sendNotification({
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.NOTIFICATION_SEND,
      data: data,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

  @override
  Future<PaginatedResult<SentNotification>> getNotificationHistory({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.NOTIFICATION_HISTORY,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final rawData = responseData['data'];

    List<dynamic> rawItems;
    Map<String, dynamic> paginationData = {};
    if (rawData is List) {
      rawItems = rawData;
    } else if (rawData is Map<String, dynamic>) {
      rawItems = rawData['notifications'] ?? rawData['data'] ?? [];
      paginationData = rawData;
    } else {
      rawItems = [];
    }

    final pagination = parsePagination(paginationData);

    return PaginatedResult(
      items: rawItems.map((e) => SentNotification.fromJson(e)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }
}
