import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/ancillary_page_model.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_ancillary_repository.dart';

class AncillaryRepository extends BaseRepository implements IAncillaryRepository {
  @override
  Future<AncillaryPageModel?> fetchPage({
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
    final responseData = response.data;
    if (responseData['success'] == false) {
      throw ApiException(
        responseData['message'] ?? 'Failed to load page',
        code: responseData['error']?['code'],
        response: responseData,
      );
    }
    final data = responseData['data'];
    if (data != null) {
      return AncillaryPageModel.fromJson(data);
    }
    return null;
  }

  @override
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
