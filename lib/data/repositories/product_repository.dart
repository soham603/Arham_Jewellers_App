import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_product_repository.dart';

class ProductRepository extends BaseRepository implements IProductRepository {
  @override
  Future<PaginatedResult<ProductModel>> fetchProducts({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_GET_ALL,
      queryParameters: queryParams,
    );
    checkApiError(response.data);
    requireData(response.data);
    return parsePaginatedList(
      response.data,
      fromJson: (e) => ProductModel.fromJson(e),
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
    checkApiError(response.data);
    requireData(response.data);
    return parsePaginatedList(
      response.data,
      fromJson: (e) => ProductModel.fromJson(e),
    );
  }

  @override
  Future<ProductModel?> fetchProductByTagNo(String tagNo) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_SEARCH,
      queryParameters: {"tagNo": tagNo},
    );
    checkApiError(response.data);
    requireData(response.data);
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      return ProductModel.fromJson(data);
    }
    return null;
  }

  @override
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

  @override
  Future<Map<String, dynamic>> fetchMissingImages({
    required String startDate,
    required String endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_MISSING_IMAGES,
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        'page': page,
        'limit': limit,
      },
    );
    checkApiError(response.data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> syncMissingImage(String id) async {
    final response = await dio.post(
      ApiUrlConstants.productSyncMissingImage(id),
    );
    checkApiError(response.data);
    return response.data;
  }
}
