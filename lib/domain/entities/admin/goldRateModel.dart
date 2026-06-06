class GoldRateModel {
  final dynamic id;
  final double rate;
  final String? source;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  GoldRateModel({
    required this.id,
    required this.rate,
    this.source,
    required this.timestamp,
    this.metadata,
  });

  factory GoldRateModel.fromJson(Map<String, dynamic> json) {
    return GoldRateModel(
      id: json['id'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      source: json['source'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'],
    );
  }
}

class GoldRateDailyTrend {
  final DateTime date;
  final double min;
  final double max;
  final double avg;
  final int count;
  final double openingRate;
  final double closingRate;

  GoldRateDailyTrend({
    required this.date,
    required this.min,
    required this.max,
    required this.avg,
    required this.count,
    required this.openingRate,
    required this.closingRate,
  });

  factory GoldRateDailyTrend.fromJson(Map<String, dynamic> json) {
    return GoldRateDailyTrend(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
      avg: (json['avg'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      openingRate: (json['openingRate'] ?? 0).toDouble(),
      closingRate: (json['closingRate'] ?? 0).toDouble(),
    );
  }
}

class GoldRateStatistics {
  final double min;
  final double max;
  final double avg;
  final double startRate;
  final double endRate;
  final double change;
  final double changePercent;
  final int totalPoints;
  final String overallTrend;
  final int upCount;
  final int downCount;
  final List<GoldRateDailyTrend> dailyTrend;

  GoldRateStatistics({
    required this.min,
    required this.max,
    required this.avg,
    required this.startRate,
    required this.endRate,
    required this.change,
    required this.changePercent,
    required this.totalPoints,
    required this.overallTrend,
    required this.upCount,
    required this.downCount,
    required this.dailyTrend,
  });

  factory GoldRateStatistics.fromJson(Map<String, dynamic> json) {
    return GoldRateStatistics(
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
      avg: (json['avg'] ?? 0).toDouble(),
      startRate: (json['startRate'] ?? 0).toDouble(),
      endRate: (json['endRate'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      totalPoints: json['totalPoints'] ?? 0,
      overallTrend: json['overallTrend'] ?? 'FLAT',
      upCount: json['upCount'] ?? 0,
      downCount: json['downCount'] ?? 0,
      dailyTrend: (json['dailyTrend'] as List<dynamic>?)
              ?.map((e) => GoldRateDailyTrend.fromJson(e))
              .toList() ??
          [],
    );
  }
}
