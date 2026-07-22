import 'package:ratnesh_gold_app/domain/entities/ancillary_page_model.dart';

abstract class IAncillaryRepository {
  Future<AncillaryPageModel?> fetchPage({
    required String pageKey,
  });
  Future<Map<String, dynamic>> updatePage({
    required String pageKey,
    required Map<String, dynamic> data,
  });
}
