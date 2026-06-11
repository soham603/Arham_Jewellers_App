import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class CarouselRepository extends BaseRepository {
  Future<List<dynamic>> fetchCarousels({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.CAROUSEL_GET_ALL,
      queryParameters: queryParams,
    );
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createCarousel({
    required dynamic data,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.CAROUSEL_CREATE,
      data: data,
    );
    return response.data;
  }

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

  Future<void> deleteCarousel({required String id}) async {
    await dio.delete(ApiUrlConstants.carouselDelete(id));
  }

  Future<Map<String, dynamic>> restoreCarousel({required String id}) async {
    final response = await dio.patch(ApiUrlConstants.carouselRestore(id));
    return response.data;
  }

  Future<Map<String, dynamic>> fetchLatestProducts({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.PRODUCTS_GET_ALL,
      queryParameters: queryParams,
    );
    return response.data;
  }
}
