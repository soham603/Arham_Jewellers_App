import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_order_repository.dart';

class OrderRepository extends BaseRepository implements IOrderRepository {
  @override
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> orderData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.PRODUCTS_CREATE_ORDER,
      data: orderData,
    );
    return response.data;
  }

  @override
  Future<PaginatedResult<UserOrderModel>> fetchUserOrders({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_USER_ALL_ORDERS,
      queryParameters: queryParams,
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final rawData = responseData["data"];
    final data = rawData is Map<String, dynamic> ? rawData : {};

    final List rawOrders = data["orders"] is List ? data["orders"] : [];
    final pagination = parsePagination(data);

    return PaginatedResult(
      items: rawOrders.map((e) => UserOrderModel.fromJson(e)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }

  @override
  Future<PaginatedResult<ProductModel>> searchProducts({
    required String query,
    Map<String, dynamic>? queryParams,
  }) async {
    final params = <String, dynamic>{
      if (query.isNotEmpty) "search": query,
      ...?queryParams,
    };
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_SEARCH,
      queryParameters: params,
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    return parsePaginatedList(
      responseData,
      fromJson: (e) => ProductModel.fromJson(e),
    );
  }

  @override
  Future<PaginatedResult<AdminOrderModel>> fetchAdminOrders({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ADMIN_ORDER_GET_ALL,
      queryParameters: queryParams,
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    final rawData = responseData["data"];
    final data = rawData is Map<String, dynamic> ? rawData : {};

    final List raw = data["results"] ?? [];
    final pagination = parsePagination(data);

    return PaginatedResult(
      items: raw.map((e) => AdminOrderModel.fromJson(e)).toList(),
      total: pagination.total,
      totalPages: pagination.totalPages,
      currentPage: pagination.currentPage,
    );
  }

  @override
  Future<Map<String, dynamic>> performOrderAction({
    required Map<String, dynamic> actionData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_ORDER_ACTION,
      data: actionData,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> performCustomOrderAction({
    required Map<String, dynamic> actionData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_CUSTOM_ORDER_ACTION,
      data: actionData,
    );
    return response.data;
  }
}
