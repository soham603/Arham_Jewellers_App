import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class AncillaryRepository extends BaseRepository {
  Future<Map<String, dynamic>> fetchPage({
    required String pageKey,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.ancillaryGetPage(pageKey),
      options: Options(
        extra: {'requiresAuth': false},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updatePage({
    required String pageKey,
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.put(
      ApiUrlConstants.ancillaryUpdatePage(pageKey),
      data: data,
      options: Options(
        extra: {'requiresAuth': true},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    return response.data;
  }
}
