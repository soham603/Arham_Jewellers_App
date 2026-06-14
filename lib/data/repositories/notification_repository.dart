import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class NotificationRepository extends BaseRepository {
  Future<Map<String, dynamic>> getAllNotifications({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.NOTIFICATION_GET_ALL,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }

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

  Future<void> updateFcmToken({
    required Map<String, dynamic> data,
  }) async {
    await dio.post(
      ApiUrlConstants.UPDATE_FCM_TOKEN,
      data: data,
    );
  }

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

  Future<Map<String, dynamic>> getNotificationHistory({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.NOTIFICATION_HISTORY,
      queryParameters: queryParams,
      options: Options(extra: {'requiresAuth': true}),
    );
    return response.data;
  }
}
