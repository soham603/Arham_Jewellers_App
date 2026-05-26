class AccessRequestUser {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String role;

  AccessRequestUser({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    required this.role,
  });

  factory AccessRequestUser.fromJson(Map<String, dynamic> json) {
    return AccessRequestUser(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'USER',
    );
  }
}

class AccessRequestModel {
  final String id;
  final String userId;
  final String status; // PENDING | APPROVED | REJECTED
  final DateTime requestedAt;
  final DateTime? approvedTill;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AccessRequestUser? user;

  AccessRequestModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.approvedTill,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory AccessRequestModel.fromJson(Map<String, dynamic> json) {
    return AccessRequestModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: DateTime.tryParse(json['requestedAt'] ?? '') ?? DateTime.now(),
      approvedTill: json['approvedTill'] != null
          ? DateTime.tryParse(json['approvedTill'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      user: json['user'] != null
          ? AccessRequestUser.fromJson(json['user'])
          : null,
    );
  }

  AccessRequestModel copyWith({String? status, DateTime? approvedTill}) {
    return AccessRequestModel(
      id: id,
      userId: userId,
      status: status ?? this.status,
      requestedAt: requestedAt,
      approvedTill: approvedTill ?? this.approvedTill,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }
}