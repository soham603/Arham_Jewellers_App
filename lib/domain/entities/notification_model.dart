class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? linkType;
  final String? linkId;
  final String? linkRef;
  final String? linkName;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.linkType,
    this.linkId,
    this.linkRef,
    this.linkName,
  });

  bool get hasDeepLink =>
      linkType != null &&
      linkType!.isNotEmpty &&
      linkType!.toLowerCase() != 'none';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['message'] ?? json['body'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      timestamp:
          DateTime.tryParse(json['createdAt'] ?? json['timestamp'] ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] ?? false,
      data: json['data'],
      linkType: json['linkType'] ?? json['link_type'],
      linkId: json['linkId'] ?? json['link_id'],
      linkRef: json['linkRef'] ?? json['link_ref'],
      linkName: json['linkName'] ?? json['link_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'linkType': linkType,
      'linkId': linkId,
      'linkRef': linkRef,
      'linkName': linkName,
    };
  }

  factory NotificationModel.fromFcmPayload(Map<String, dynamic> data) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? data['notification_title'] ?? '',
      body: data['body'] ?? data['notification_body'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image_url'],
      timestamp: DateTime.now(),
      isRead: false,
      linkType: data['linkType'] ?? data['link_type'],
      linkId: data['linkId'] ?? data['link_id'],
      linkRef: data['linkRef'] ?? data['link_ref'],
      linkName: data['linkName'] ?? data['link_name'],
      data: Map<String, dynamic>.from(data)
        ..remove('title')
        ..remove('body')
        ..remove('notification_title')
        ..remove('notification_body')
        ..remove('linkType')
        ..remove('linkId')
        ..remove('linkRef')
        ..remove('linkName'),
    );
  }
}
