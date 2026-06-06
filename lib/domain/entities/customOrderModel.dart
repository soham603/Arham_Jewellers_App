class CustomOrderModel {
  final String id;
  final String partyCode;
  final String partyName;
  final String? area;
  final String contactNumber;
  final String itemName;
  final String? weight;
  final String? noOfPieces;
  final String? size;
  final String? lengthBroadness;
  final String? productDescription;
  final String purity;
  final String style;
  final String marking;
  final List<String> referenceImages;
  final String status;
  final String? adminMessage;
  final String? assignedKarigarId;
  final String? assignedKarigarName;
  final String? talkedToStaffName;
  final String? assignAdminNotes;
  final String? completeAdminNotes;
  final String? deliveryDate;
  final bool isCustomOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomOrderModel({
    required this.id,
    required this.partyCode,
    required this.partyName,
    this.area,
    required this.contactNumber,
    required this.itemName,
    this.weight,
    this.noOfPieces,
    this.size,
    this.lengthBroadness,
    this.productDescription,
    required this.purity,
    required this.style,
    required this.marking,
    this.referenceImages = const [],
    this.status = 'PENDING',
    this.adminMessage,
    this.assignedKarigarId,
    this.assignedKarigarName,
    this.talkedToStaffName,
    this.assignAdminNotes,
    this.completeAdminNotes,
    this.deliveryDate,
    this.isCustomOrder = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomOrderModel(
      id: json['id']?.toString() ?? '',
      partyCode: json['partyCode']?.toString() ?? '',
      partyName: json['partyName']?.toString() ?? '',
      area: json['area']?.toString(),
      contactNumber: json['contactNumber']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      weight: json['weight']?.toString(),
      noOfPieces: json['noOfPieces']?.toString(),
      size: json['size']?.toString(),
      lengthBroadness: json['lengthBroadness']?.toString(),
      productDescription: json['productDescription']?.toString(),
      purity: json['purity']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      marking: json['marking']?.toString() ?? '',
      referenceImages: json['referenceImages'] != null
          ? List<String>.from(
              (json['referenceImages'] as List).map((e) => e.toString()))
          : [],
      status: json['status']?.toString() ?? 'PENDING',
      adminMessage: json['adminMessage']?.toString(),
      assignedKarigarId: json['assignedKarigarId']?.toString(),
      assignedKarigarName: json['assignedKarigarName']?.toString(),
      talkedToStaffName: json['talkedToStaffName']?.toString(),
      assignAdminNotes: json['assignAdminNotes']?.toString(),
      completeAdminNotes: json['completeAdminNotes']?.toString(),
      deliveryDate: json['deliveryDate']?.toString(),
      isCustomOrder: json['isCustomOrder'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
