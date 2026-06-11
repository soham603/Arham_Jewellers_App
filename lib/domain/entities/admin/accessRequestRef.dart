class AccessRequestRef {

  final String id;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedTill;
  final DateTime createdAt;

  AccessRequestRef({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.approvedTill,
    required this.createdAt,
  });

  factory AccessRequestRef.fromJson(Map<String, dynamic> json) {
    return AccessRequestRef(
      id: json['id'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      approvedTill: json['approvedTill'] != null
          ? DateTime.parse(json['approvedTill'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'approvedTill': approvedTill?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AccessRequestRef copyWith({
    String? id,
    String? status,
    DateTime? requestedAt,
    DateTime? approvedTill,
    DateTime? createdAt,
  }) {
    return AccessRequestRef(
      id: id ?? this.id,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedTill: approvedTill ?? this.approvedTill,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
