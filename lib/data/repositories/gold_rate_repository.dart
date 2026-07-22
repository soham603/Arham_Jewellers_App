import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';
import 'package:ratnesh_gold_app/domain/entities/gold_rate_history_result.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_gold_rate_repository.dart';

class GoldRateRepository extends BaseRepository implements IGoldRateRepository {
  @override
  Future<GoldRateModel?> fetchCurrentRate() async {
    final response = await dio.get(
      ApiUrlConstants.LIVE_RATE_CURRENT,
      options: Options(
        extra: {'requiresAuth': false},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );
    final responseData = response.data;
    checkApiError(responseData);
    final data = responseData['data'];
    if (data != null) {
      return GoldRateModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<GoldRateHistoryResult> fetchHistory({
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
    final responseData = response.data;
    checkApiError(responseData);

    final rawData = responseData['data'];
    List<GoldRateModel> items = [];
    GoldRateStatistics? statistics;

    if (rawData is List) {
      items = rawData.map((e) => GoldRateModel.fromJson(e)).toList();
    } else if (rawData is Map<String, dynamic>) {
      final dailyTrend = rawData['dailyTrend'];
      if (dailyTrend is List) {
        items = dailyTrend.map<GoldRateModel>((e) {
          final dateStr = e['date'] ?? '';
          final rawRate = e['closingRate'] ?? e['avg'] ?? 0;
          final closingRate = rawRate is num
              ? rawRate.toDouble()
              : double.tryParse(rawRate.toString()) ?? 0.0;
          return GoldRateModel(
            id: null,
            rate: closingRate,
            source: null,
            timestamp: DateTime.tryParse(dateStr) ?? DateTime.now(),
            metadata: null,
          );
        }).toList();
      }

      if (rawData['summary'] != null) {
        statistics = GoldRateStatistics.fromJson(rawData['summary']);
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return GoldRateHistoryResult(items: items, statistics: statistics);
  }

  @override
  Future<GoldRateStatistics?> fetchStatistics({
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
    final responseData = response.data;
    checkApiError(responseData);
    final data = responseData['data'];
    if (data != null && data['summary'] != null) {
      return GoldRateStatistics.fromJson(data['summary']);
    }
    return null;
  }

  @override
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
