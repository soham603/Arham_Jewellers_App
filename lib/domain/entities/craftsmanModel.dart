class CraftsmanModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? accountName;
  final String? areaName;
  final bool isActive;
  final String? balanceSheetGroupName;
  final String? cityName;
  final String? emailId;
  final String? referenceBy;
  final String? state;
  final String? taluka;
  final String? tanNo;
  final String? whatsAppNo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;

  CraftsmanModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.accountName,
    this.areaName,
    this.isActive = true,
    this.balanceSheetGroupName,
    this.cityName,
    this.emailId,
    this.referenceBy,
    this.state,
    this.taluka,
    this.tanNo,
    this.whatsAppNo,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory CraftsmanModel.fromJson(Map<String, dynamic> json) {
    return CraftsmanModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString(),
      areaName: json['areaName']?.toString(),
      isActive: json['isActive'] ?? true,
      balanceSheetGroupName: json['balanceSheetGroupName']?.toString(),
      cityName: json['cityName']?.toString(),
      emailId: json['emailId']?.toString(),
      referenceBy: json['referenceBy']?.toString(),
      state: json['state']?.toString(),
      taluka: json['taluka']?.toString(),
      tanNo: json['tanNo']?.toString(),
      whatsAppNo: json['whatsAppNo']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
      deletedBy: json['deletedBy']?.toString(),
    );
  }

  CraftsmanModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? accountName,
    String? areaName,
    bool? isActive,
    String? balanceSheetGroupName,
    String? cityName,
    String? emailId,
    String? referenceBy,
    String? state,
    String? taluka,
    String? tanNo,
    String? whatsAppNo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CraftsmanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountName: accountName ?? this.accountName,
      areaName: areaName ?? this.areaName,
      isActive: isActive ?? this.isActive,
      balanceSheetGroupName: balanceSheetGroupName ?? this.balanceSheetGroupName,
      cityName: cityName ?? this.cityName,
      emailId: emailId ?? this.emailId,
      referenceBy: referenceBy ?? this.referenceBy,
      state: state ?? this.state,
      taluka: taluka ?? this.taluka,
      tanNo: tanNo ?? this.tanNo,
      whatsAppNo: whatsAppNo ?? this.whatsAppNo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  String get displayName {
    final parts = <String>[name];
    if (accountName != null && accountName!.isNotEmpty) parts.add(accountName!);
    if (areaName != null && areaName!.isNotEmpty) parts.add(areaName!);
    return parts.join(' · ');
  }
}
