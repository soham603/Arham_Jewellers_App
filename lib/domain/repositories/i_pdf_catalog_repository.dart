import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';

abstract class IPdfCatalogRepository {
  Future<List<PdfCatalogModel>> fetchActiveCatalogs();

  Future<List<PdfCatalogModel>> fetchAdminCatalogs();

  Future<Map<String, dynamic>> createCatalog({required dynamic data});

  Future<Map<String, dynamic>> deleteCatalog({required String id});

  Future<Map<String, dynamic>> toggleCatalogPage({
    required String pageId,
    required bool isActive,
  });
}
