import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CraftsmanController extends GetxController {
  static CraftsmanController get instance => Get.find();

  final _craftsmen = <CraftsmanModel>[].obs;
  List<CraftsmanModel> get craftsmen => _craftsmen;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    if (_craftsmen.isEmpty) {
      fetchCraftsmen();
    }
  }

  Future<void> fetchCraftsmen() async {
    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _state.value = CurrentAppState.LOADING;

      final response = await httpClient.get(
        ApiUrlConstants.CRAFTSMAN_GET_ALL,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = response.data['data'];
        final List raw = data is List
            ? data
            : data is Map<String, dynamic>
                ? (data['craftsmen'] ?? data['results'] ?? data['data'] ?? [])
                : [];
        _craftsmen.value =
            raw.map((e) => CraftsmanModel.fromJson(e)).toList();
        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      Logger.error("CraftsmanController", "fetchCraftsmen error: $e\n$st");
      _state.value = CurrentAppState.ERROR;
    } finally {
      _isLoading.value = false;
    }
  }

  CraftsmanModel? getById(String id) {
    try {
      return _craftsmen.firstWhere((c) => c.id == id);
    } catch (e) {
      Logger.warning("CraftsmanController", "getById: craftsman not found for id=$id");
      return null;
    }
  }
}
