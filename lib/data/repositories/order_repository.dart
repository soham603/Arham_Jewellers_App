import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class OrderRepository extends BaseRepository {
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> orderData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.PRODUCTS_CREATE_ORDER,
      data: orderData,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fetchUserOrders({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_USER_ALL_ORDERS,
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> searchProducts({
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
    return response.data;
  }

  Future<Map<String, dynamic>> fetchAdminOrders({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ADMIN_ORDER_GET_ALL,
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> performOrderAction({
    required Map<String, dynamic> actionData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.ADMIN_ORDER_ACTION,
      data: actionData,
    );
    return response.data;
  }

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
