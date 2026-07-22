import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';

abstract class ICarouselRepository {
  Future<List<CarouselModel>> fetchCarousels({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> createCarousel({
    required dynamic data,
  });
  Future<Map<String, dynamic>?> editCarousel({
    required String id,
    required dynamic data,
  });
  Future<void> deleteCarousel({required String id});
  Future<Map<String, dynamic>> restoreCarousel({required String id});
  Future<PaginatedResult<ProductModel>> fetchLatestProducts({
    Map<String, dynamic>? queryParams,
  });
}
