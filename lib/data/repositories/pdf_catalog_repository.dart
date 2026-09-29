import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_pdf_catalog_repository.dart';

class PdfCatalogRepository extends BaseRepository
    implements IPdfCatalogRepository {
  @override
  Future<List<PdfCatalogModel>> fetchActiveCatalogs() async {
    final list = await _fetchCatalogList(ApiUrlConstants.PDF_CATALOG_ACTIVE);
    return list;
  }

  @override
  Future<List<PdfCatalogModel>> fetchAdminCatalogs() async {
    final list = await _fetchCatalogList(ApiUrlConstants.PDF_CATALOG_GET_ALL);
    return list;
  }

  @override
  Future<Map<String, dynamic>> createCatalog({required dynamic data}) async {
    final response = await dio.post(
      ApiUrlConstants.PDF_CATALOG_CREATE,
      data: data,
      options: Options(
        extra: {'requiresAuth': true},
        sendTimeout: AppTimeouts.uploadSend,
        receiveTimeout: AppTimeouts.uploadReceive,
      ),
    );
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> deleteCatalog({required String id}) async {
    final response = await dio.delete(ApiUrlConstants.pdfCatalogDelete(id));
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> toggleCatalogPage({
    required String pageId,
    required bool isActive,
  }) async {
    final response = await dio.patch(
      ApiUrlConstants.pdfCatalogTogglePage(pageId),
      data: {'isActive': isActive},
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<PdfCatalogModel>> _fetchCatalogList(String path) async {
    final response = await dio.get(path);

    final raw = response.data;
    if (raw is! Map) return [];

    final data = Map<String, dynamic>.from(raw);

    checkApiError(data);

    final list = data['data'];
    if (list is! List) return [];

    return list
        .map((e) => PdfCatalogModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
