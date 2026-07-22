import 'package:ratnesh_gold_app/domain/entities/admin/handsetChangeModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';

abstract class IAuthRepository {
  Future<({int statusCode, Map<String, dynamic> data})> loginUser({
    required String phone,
    required String password,
    required String deviceId,
    String? fcmToken,
  });
  Future<({int statusCode, Map<String, dynamic> data})> loginAdmin({
    required String phone,
    required String password,
    required String deviceId,
    String? fcmToken,
  });
  Future<({int statusCode, Map<String, dynamic> data})> registerUser({
    required Map<String, dynamic> userData,
  });
  Future<({int statusCode, Map<String, dynamic> data})> forgotPassword({
    required String phone,
  });
  Future<PaginatedResult<HandsetChangeRequestModel>> fetchHandsetRequests({
    Map<String, dynamic>? queryParams,
  });
  Future<({int statusCode, Map<String, dynamic> data})> handleHandsetRequest({
    required String requestId,
    required String action,
    String? rejectionReason,
  });
}
