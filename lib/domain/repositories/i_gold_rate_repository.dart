import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';
import 'package:ratnesh_gold_app/domain/entities/gold_rate_history_result.dart';

abstract class IGoldRateRepository {
  Future<GoldRateModel?> fetchCurrentRate();
  Future<GoldRateHistoryResult> fetchHistory({
    Map<String, dynamic>? queryParams,
  });
  Future<GoldRateStatistics?> fetchStatistics({
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> updateRate({
    required Map<String, dynamic> rateData,
  });
}
