class HandsetChangeRequestModel {
  final String id;
  final String userId;
  final String? userRole;
  final String? userName;
  final String? userPhoneNumber;
  final String channel;
  final String? oldDeviceId;
  final String? oldDeviceName;
  final String? oldUuid;
  final String newDeviceId;
  final String newDeviceName;
  final String? newUuid;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  HandsetChangeRequestModel({
    required this.id,
    required this.userId,
    this.userRole,
    this.userName,
    this.userPhoneNumber,
    this.channel = 'DEVICE',
    this.oldDeviceId,
    this.oldDeviceName,
    this.oldUuid,
    required this.newDeviceId,
    required this.newDeviceName,
    this.newUuid,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isBrowser => channel.toUpperCase() == 'BROWSER';

  factory HandsetChangeRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return HandsetChangeRequestModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? user?['id'] ?? '',
      userRole: json['userRole'] ?? user?['role'],
      userName: json['userName'] ?? user?['name'],
      userPhoneNumber: json['userPhoneNumber'] ?? user?['phoneNumber'],
      channel: json['channel'] ?? 'DEVICE',
      oldDeviceId: json['oldDeviceId'],
      oldDeviceName: json['oldDeviceName'],
      oldUuid: json['oldUuid'],
      newDeviceId: json['newDeviceId'] ?? '',
      newDeviceName: json['newDeviceName'] ?? '',
      newUuid: json['newUuid'],
      status: json['status'] ?? 'PENDING',
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userRole': userRole,
      'userName': userName,
      'userPhoneNumber': userPhoneNumber,
      'channel': channel,
      'oldDeviceId': oldDeviceId,
      'oldDeviceName': oldDeviceName,
      'oldUuid': oldUuid,
      'newDeviceId': newDeviceId,
      'newDeviceName': newDeviceName,
      'newUuid': newUuid,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  HandsetChangeRequestModel copyWith({
    String? id,
    String? userId,
    String? userRole,
    String? userName,
    String? userPhoneNumber,
    String? channel,
    String? oldDeviceId,
    String? oldDeviceName,
    String? oldUuid,
    String? newDeviceId,
    String? newDeviceName,
    String? newUuid,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HandsetChangeRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      channel: channel ?? this.channel,
      oldDeviceId: oldDeviceId ?? this.oldDeviceId,
      oldDeviceName: oldDeviceName ?? this.oldDeviceName,
      oldUuid: oldUuid ?? this.oldUuid,
      newDeviceId: newDeviceId ?? this.newDeviceId,
      newDeviceName: newDeviceName ?? this.newDeviceName,
      newUuid: newUuid ?? this.newUuid,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
