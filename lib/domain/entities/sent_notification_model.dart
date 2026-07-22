class SentNotification {
  final String id;
  final String title;
  final String body;
  final String targetType;
  final String? targetValue;
  final DateTime sentAt;
  final String? sentBy;
  final int? recipientCount;

  SentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.targetType,
    this.targetValue,
    required this.sentAt,
    this.sentBy,
    this.recipientCount,
  });

  factory SentNotification.fromJson(Map<String, dynamic> json) {
    return SentNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetType: json['targetType'] ?? json['target_type'] ?? 'all',
      targetValue: json['targetValue'] ?? json['target_value'],
      sentAt: DateTime.tryParse(json['sentAt'] ?? json['sent_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      sentBy: json['sentBy'] ?? json['sent_by'],
      recipientCount: json['recipientCount'] ?? json['recipient_count'],
    );
  }
}
