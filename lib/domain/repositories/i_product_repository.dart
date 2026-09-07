import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';

abstract class IProductRepository {
  Future<PaginatedResult<ProductModel>> fetchProducts({
    Map<String, dynamic>? queryParams,
  });
  Future<PaginatedResult<ProductModel>> searchProducts({
    required String query,
    Map<String, dynamic>? queryParams,
  });
  Future<ProductModel?> fetchProductByTagNo(String tagNo);
  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required dynamic data,
  });
  Future<Map<String, dynamic>> fetchMissingImages({
    required String startDate,
    required String endDate,
    int page,
    int limit,
  });
  Future<Map<String, dynamic>> syncMissingImage(String id);
}
