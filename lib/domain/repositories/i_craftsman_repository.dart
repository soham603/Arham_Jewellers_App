import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';

abstract class ICraftsmanRepository {
  Future<List<CraftsmanModel>> fetchCraftsmen();
}
