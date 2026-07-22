import 'package:ratnesh_gold_app/domain/entities/admin/adminAccessModel.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/userSearchModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';

abstract class IAdminAccessRepository {
  Future<PaginatedResult<AccessRequestModel>> fetchAccessRequests({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> handleAccess({
    required Map<String, dynamic> actionData,
  });
  Future<PaginatedResult<UserSearchModel>> fetchUsers({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> toggleUserActivation({
    required Map<String, dynamic> data,
  });
  Future<Map<String, dynamic>> createAdmin({
    required Map<String, dynamic> data,
  });
  Future<Map<String, dynamic>> toggleRetailer({
    required Map<String, dynamic> data,
  });
  Future<Map<String, dynamic>> adminResetPassword({
    required Map<String, dynamic> data,
  });
}
