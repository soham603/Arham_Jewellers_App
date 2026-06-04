class GoldRateModel {
  final String id;
  final double ratePerGram;
  final String? setBy;
  final DateTime createdAt;

  GoldRateModel({
    required this.id,
    required this.ratePerGram,
    this.setBy,
    required this.createdAt,
  });

  factory GoldRateModel.fromJson(Map<String, dynamic> json) {
    return GoldRateModel(
      id: json['id'] ?? '',
      ratePerGram: (json['ratePerGram'] ?? 0).toDouble(),
      setBy: json['setBy'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
