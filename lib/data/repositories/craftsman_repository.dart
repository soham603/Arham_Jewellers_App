import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_craftsman_repository.dart';

class CraftsmanRepository extends BaseRepository implements ICraftsmanRepository {
  @override
  Future<List<CraftsmanModel>> fetchCraftsmen() async {
    final response = await dio.get(ApiUrlConstants.CRAFTSMAN_GET_ALL);
    checkApiError(response.data);
    final data = response.data['data'];

    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      rawList = data['craftsmen'] ?? data['results'] ?? data['data'] ?? [];
    } else {
      rawList = [];
    }

    return rawList.map((e) => CraftsmanModel.fromJson(e)).toList();
  }
}
