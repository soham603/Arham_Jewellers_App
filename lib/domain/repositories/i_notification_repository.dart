import 'package:ratnesh_gold_app/domain/entities/admin/userSearchModel.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/sent_notification_model.dart';

abstract class INotificationRepository {
  Future<PaginatedResult<NotificationModel>> getAllNotifications({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> markNotificationsAsRead({
    required Map<String, dynamic> data,
  });
  Future<Map<String, dynamic>> sendNotification({
    required Map<String, dynamic> data,
  });
  Future<String?> uploadNotificationImage({
    required String filePath,
  });
  Future<PaginatedResult<SentNotification>> getNotificationHistory({
    Map<String, dynamic>? queryParams,
  });
  Future<PaginatedResult<UserSearchModel>> searchEligibleUsers({
    Map<String, dynamic>? queryParams,
  });
}
