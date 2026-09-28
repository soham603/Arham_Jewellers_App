class SentNotificationRecipient {
  final String id;
  final String? name;
  final String? phoneNumber;

  SentNotificationRecipient({
    required this.id,
    this.name,
    this.phoneNumber,
  });

  factory SentNotificationRecipient.fromJson(Map<String, dynamic> json) {
    return SentNotificationRecipient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }

  String get label =>
      (name != null && name!.trim().isNotEmpty) ? name! : (phoneNumber ?? id);
}

class SentNotificationFailure {
  final String? userId;
  final String? name;
  final String? phoneNumber;
  final String? code;
  final String? message;

  SentNotificationFailure({
    this.userId,
    this.name,
    this.phoneNumber,
    this.code,
    this.message,
  });

  factory SentNotificationFailure.fromJson(Map<String, dynamic> json) {
    return SentNotificationFailure(
      userId: json['userId']?.toString(),
      name: json['name']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      code: json['code']?.toString(),
      message: json['message']?.toString(),
    );
  }

  String get label =>
      (name != null && name!.trim().isNotEmpty) ? name! : (phoneNumber ?? 'Unknown user');
}

class SentNotification {
  final String id;
  final String title;
  final String body;
  final String targetType;
  final String? targetValue;
  final DateTime sentAt;
  final String? sentBy;
  final int? recipientCount;
  final String? pushMode;
  final int? pushSuccessCount;
  final int? pushFailureCount;
  final String? pushError;
  final int? noTokenCount;
  final List<SentNotificationFailure> failures;
  final List<SentNotificationRecipient> recipients;

  SentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.targetType,
    this.targetValue,
    required this.sentAt,
    this.sentBy,
    this.recipientCount,
    this.pushMode,
    this.pushSuccessCount,
    this.pushFailureCount,
    this.pushError,
    this.noTokenCount,
    this.failures = const [],
    this.recipients = const [],
  });

  factory SentNotification.fromJson(Map<String, dynamic> json) {
    final push = json['push'];
    final delivery = json['delivery'];
    final pushMap = push is Map ? push : null;
    final deliveryMap = delivery is Map ? delivery : null;

    int? toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    return SentNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      targetType: json['targetType'] ?? json['target_type'] ?? 'all',
      targetValue: json['targetValue'] ?? json['target_value'],
      sentAt: DateTime.tryParse(json['sentAt'] ??
              json['sent_at'] ??
              json['timestamp'] ??
              json['createdAt'] ??
              '') ??
          DateTime.now(),
      sentBy: json['sentBy'] ?? json['sent_by'],
      recipientCount: toInt(json['recipientCount'] ?? json['recipient_count']),
      pushMode: pushMap?['mode']?.toString(),
      pushSuccessCount: toInt(pushMap?['successCount']),
      pushFailureCount: toInt(pushMap?['failureCount']),
      pushError: pushMap?['error']?.toString(),
      noTokenCount: toInt(deliveryMap?['noToken']),
      failures: (deliveryMap?['failures'] is List)
          ? (deliveryMap!['failures'] as List)
              .whereType<Map>()
              .map((e) => SentNotificationFailure.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      recipients: (json['recipients'] is List)
          ? (json['recipients'] as List)
              .whereType<Map>()
              .map((e) => SentNotificationRecipient.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}
