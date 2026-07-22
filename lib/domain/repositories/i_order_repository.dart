import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';

abstract class IOrderRepository {
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> orderData,
  });
  Future<PaginatedResult<UserOrderModel>> fetchUserOrders({
    Map<String, dynamic>? queryParams,
  });
  Future<PaginatedResult<ProductModel>> searchProducts({
    required String query,
    Map<String, dynamic>? queryParams,
  });
  Future<PaginatedResult<AdminOrderModel>> fetchAdminOrders({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> performOrderAction({
    required Map<String, dynamic> actionData,
  });
  Future<Map<String, dynamic>> performCustomOrderAction({
    required Map<String, dynamic> actionData,
  });
}
