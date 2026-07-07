import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class GoldRateRepository extends BaseRepository {
  Future<Map<String, dynamic>> fetchCurrentRate() async {
    final response = await dio.get(
      ApiUrlConstants.LIVE_RATE_CURRENT,
      options: Options(
        extra: {'requiresAuth': false},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fetchHistory({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.LIVE_RATE_HISTORY,
      queryParameters: queryParams,
      options: Options(
        extra: {'requiresAuth': false},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fetchStatistics({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await dio.get(
      ApiUrlConstants.LIVE_RATE_STATISTICS,
      queryParameters: queryParams,
      options: Options(
        extra: {'requiresAuth': false},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateRate({
    required Map<String, dynamic> rateData,
  }) async {
    final response = await dio.post(
      ApiUrlConstants.LIVE_RATE_UPDATE,
      data: rateData,
      options: Options(
        extra: {'requiresAuth': true},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    return response.data;
  }
}
