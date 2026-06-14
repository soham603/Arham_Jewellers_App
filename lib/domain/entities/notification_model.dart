class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['message'] ?? json['body'] ?? '',
      timestamp: DateTime.tryParse(json['createdAt'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromFcmPayload(Map<String, dynamic> data) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? data['notification_title'] ?? '',
      body: data['body'] ?? data['notification_body'] ?? '',
      timestamp: DateTime.now(),
      isRead: false,
      data: Map<String, dynamic>.from(data)..remove('title')..remove('body')..remove('notification_title')..remove('notification_body'),
    );
  }
}
