import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class CraftsmanRepository extends BaseRepository {
  Future<List<dynamic>> fetchCraftsmen() async {
    final response = await dio.get(ApiUrlConstants.CRAFTSMAN_GET_ALL);
    final data = response.data['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return data['craftsmen'] ?? data['results'] ?? data['data'] ?? [];
    }
    return [];
  }
}
