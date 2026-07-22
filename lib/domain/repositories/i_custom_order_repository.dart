abstract class ICustomOrderRepository {
  Future<Map<String, dynamic>> createCustomOrder({
    required dynamic data,
  });
  Future<Map<String, dynamic>> modifyCustomOrder({
    required String orderId,
    required dynamic data,
  });
  Future<Map<String, dynamic>> deleteCustomOrder({
    required String orderId,
  });
}
