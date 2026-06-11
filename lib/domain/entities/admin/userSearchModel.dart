import 'package:ratnesh_gold_app/domain/entities/admin/accessRequestRef.dart';

class UserSearchModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String? city;
  final String? area;
  final String? companyName;
  final String accountStatus;
  final String userActivationStatus;
  final DateTime? enableAccessTill;
  final DateTime createdAt;
  final List<AccessRequestRef>? accessRequests;
  final String? deviceId;
  final String? deviceName;
  final bool? isRetailer;
  final String? forgotPasswordStatus;

  UserSearchModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.city,
    this.area,
    this.companyName,
    required this.accountStatus,
    required this.userActivationStatus,
    this.enableAccessTill,
    required this.createdAt,
    this.accessRequests,
    this.deviceId,
    this.deviceName,
    this.isRetailer,
    this.forgotPasswordStatus,
  });

  factory UserSearchModel.fromJson(Map<String, dynamic> json) {
    return UserSearchModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'USER',
      city: json['city'],
      area: json['area'],
      companyName: json['companyName'],
      accountStatus: json['accountStatus'] ?? 'PENDING',
      userActivationStatus: json['userActivationStatus'] ?? 'ACTIVE',
      enableAccessTill: json['enableAccessTill'] != null
          ? DateTime.parse(json['enableAccessTill'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      accessRequests: json['accessRequests'] != null
          ? (json['accessRequests'] as List)
              .map((e) => AccessRequestRef.fromJson(e))
              .toList()
          : null,
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      isRetailer: json['retailUser'] ?? false,
      forgotPasswordStatus: json['forgotPasswordStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'city': city,
      'area': area,
      'companyName': companyName,
      'accountStatus': accountStatus,
      'userActivationStatus': userActivationStatus,
      'enableAccessTill': enableAccessTill?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'accessRequests': accessRequests?.map((e) => e.toJson()).toList(),
      'deviceId': deviceId,
      'deviceName': deviceName,
      'retailUser': isRetailer,
      'forgotPasswordStatus': forgotPasswordStatus,
    };
  }

  UserSearchModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? city,
    String? area,
    String? companyName,
    String? accountStatus,
    String? userActivationStatus,
    DateTime? enableAccessTill,
    DateTime? createdAt,
    List<AccessRequestRef>? accessRequests,
    String? deviceId,
    String? deviceName,
    bool? isRetailer,
    String? forgotPasswordStatus,
  }) {
    return UserSearchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      city: city ?? this.city,
      area: area ?? this.area,
      companyName: companyName ?? this.companyName,
      accountStatus: accountStatus ?? this.accountStatus,
      userActivationStatus: userActivationStatus ?? this.userActivationStatus,
      enableAccessTill: enableAccessTill ?? this.enableAccessTill,
      createdAt: createdAt ?? this.createdAt,
      accessRequests: accessRequests ?? this.accessRequests,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      isRetailer: isRetailer ?? this.isRetailer,
      forgotPasswordStatus: forgotPasswordStatus ?? this.forgotPasswordStatus,
    );
  }
}
