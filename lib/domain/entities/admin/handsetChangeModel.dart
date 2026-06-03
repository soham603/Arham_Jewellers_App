class HandsetChangeRequestModel {
  final String id;
  final String userId;
  final String? userRole;
  final String? userName;
  final String? userPhoneNumber;
  final String newDeviceId;
  final String newDeviceName;
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
    required this.newDeviceId,
    required this.newDeviceName,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HandsetChangeRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return HandsetChangeRequestModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? user?['id'] ?? '',
      userRole: json['userRole'] ?? user?['role'],
      userName: json['userName'] ?? user?['name'],
      userPhoneNumber: json['userPhoneNumber'] ?? user?['phoneNumber'],
      newDeviceId: json['newDeviceId'] ?? '',
      newDeviceName: json['newDeviceName'] ?? '',
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
      'newDeviceId': newDeviceId,
      'newDeviceName': newDeviceName,
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
    String? newDeviceId,
    String? newDeviceName,
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
      newDeviceId: newDeviceId ?? this.newDeviceId,
      newDeviceName: newDeviceName ?? this.newDeviceName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
