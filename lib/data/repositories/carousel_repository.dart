import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_carousel_repository.dart';

class CarouselRepository extends BaseRepository implements ICarouselRepository {
  @override
  Future<List<CarouselModel>> fetchCarousels({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.CAROUSEL_GET_ALL,
      queryParameters: queryParams,
    );
    checkApiError(response.data);
    final data = response.data['data'] ?? [];
    if (data is List) {
      return data.map((e) => CarouselModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> createCarousel({
    required dynamic data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.CAROUSEL_CREATE,
      data: data,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>?> editCarousel({
    required String id,
    required dynamic data,
  }) async {
    final response = await dio.put(
      ApiUrlConstants.carouselEdit(id),
      data: data,
    );
    if (response.data == null || response.data is! Map) return null;
    return response.data;
  }

  @override
  Future<void> deleteCarousel({required String id}) async {
    await dio.delete(ApiUrlConstants.carouselDelete(id));
  }

  @override
  Future<Map<String, dynamic>> restoreCarousel({required String id}) async {
    final response = await dio.patch(ApiUrlConstants.carouselRestore(id));
    return response.data;
  }

  @override
  Future<PaginatedResult<ProductModel>> fetchLatestProducts({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_GET_ALL,
      queryParameters: queryParams,
    );
    final responseData = response.data;
    checkApiError(responseData);
    requireData(responseData);
    return parsePaginatedList(
      responseData,
      listKey: 'data',
      fromJson: (e) => ProductModel.fromJson(e),
    );
  }
}
