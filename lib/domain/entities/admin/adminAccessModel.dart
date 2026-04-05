class AccessUser {
  final String id;
  final String? name;
  final String? email;
  final String phoneNumber;
  final String? role;

  AccessUser({
    required this.id,
    this.name,
    this.email,
    required this.phoneNumber,
    this.role,
  });

  factory AccessUser.fromJson(Map<String, dynamic> json) {
    return AccessUser(
      id: json['id'] ?? "",
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? "",
      role: json['role'],
    );
  }
}

class AccessRequestModel {
  final String id;
  final String status;
  final String userId;
  final DateTime? createdAt;
  final AccessUser user;

  AccessRequestModel({
    required this.id,
    required this.status,
    required this.userId,
    required this.user,
    this.createdAt,
  });

  factory AccessRequestModel.fromJson(Map<String, dynamic> json) {
    return AccessRequestModel(
      id: json['id'] ?? "",
      status: json['status'] ?? "",
      userId: json['userId'] ?? "",
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      user: AccessUser.fromJson(json['user'] ?? {}),
    );
  }
}