class UserModel {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final bool isDeleted;
  final String enableAccessTill;
  final String createdAt;
  final String updatedAt;
  final String? accountStatus;
  final String? area;
  final String? city;
  final String? companyName;
  final String? deviceId;
  final String? deviceName;
  final String? gstNumber;
  final String? pincode;
  final String? role;
  final String? userActivationStatus;
  final bool? completedProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.isDeleted,
    required this.enableAccessTill,
    required this.createdAt,
    required this.updatedAt,
    this.accountStatus,
    this.area,
    this.city,
    this.companyName,
    this.deviceId,
    this.deviceName,
    this.gstNumber,
    this.pincode,
    this.role,
    this.userActivationStatus,
    this.completedProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      enableAccessTill: json['enableAccessTill'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      accountStatus: json['accountStatus'],
      area: json['area'],
      city: json['city'],
      companyName: json['companyName'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      gstNumber: json['gstNumber'],
      pincode: json['pincode'],
      role: json['role'],
      userActivationStatus: json['userActivationStatus'],
      completedProfile: json['completedProfile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'isDeleted': isDeleted,
      'enableAccessTill': enableAccessTill,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'accountStatus': accountStatus,
      'area': area,
      'city': city,
      'companyName': companyName,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'gstNumber': gstNumber,
      'pincode': pincode,
      'role': role,
      'userActivationStatus': userActivationStatus,
      'completedProfile': completedProfile,
    };
  }
}