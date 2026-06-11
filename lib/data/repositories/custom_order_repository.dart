import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class CustomOrderRepository extends BaseRepository {
  Future<Map<String, dynamic>> createCustomOrder({
    required dynamic data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.CUSTOM_ORDER_CREATE,
      data: data,
    );
    return response.data;
  }

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

  Future<void> deleteCustomOrder({
    required String orderId,
  }) async {
    await dio.delete(
      ApiUrlConstants.customOrderDelete(orderId),
    );
  }
}
