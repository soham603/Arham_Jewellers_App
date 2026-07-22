import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';

class GoldRateHistoryResult {
  final List<GoldRateModel> items;
  final GoldRateStatistics? statistics;

  GoldRateHistoryResult({
    required this.items,
    this.statistics,
  });
}
