class CraftsmanModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? accountName;
  final String? areaName;

  CraftsmanModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.accountName,
    this.areaName,
  });

  factory CraftsmanModel.fromJson(Map<String, dynamic> json) {
    return CraftsmanModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString(),
      areaName: json['areaName']?.toString(),
    );
  }

  String get displayName {
    final parts = <String>[name];
    if (accountName != null && accountName!.isNotEmpty) parts.add(accountName!);
    if (areaName != null && areaName!.isNotEmpty) parts.add(areaName!);
    return parts.join(' · ');
  }
}
