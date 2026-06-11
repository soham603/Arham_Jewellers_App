import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class ProductRepository extends BaseRepository {
  Future<Map<String, dynamic>> fetchProducts({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_GET_ALL,
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

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required dynamic data,
  }) async {
    final response = await dio.patch(
      ApiUrlConstants.productsUpdate(id),
      data: data,
    );
    return response.data;
  }
}
