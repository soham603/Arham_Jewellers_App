import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_custom_order_repository.dart';

class CustomOrderRepository extends BaseRepository implements ICustomOrderRepository {
  @override
  Future<Map<String, dynamic>> createCustomOrder({
    required dynamic data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.CUSTOM_ORDER_CREATE,
      data: data,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> modifyCustomOrder({
    required String orderId,
    required dynamic data,
  }) async {
    final response = await dio.patch(
      ApiUrlConstants.customOrderModify(orderId),
      data: data,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> deleteCustomOrder({
    required String orderId,
  }) async {
    final response = await dio.delete(
      ApiUrlConstants.customOrderDelete(orderId),
    );
    return response.data as Map<String, dynamic>;
  }
}
