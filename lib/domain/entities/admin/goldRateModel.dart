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
