
class UserOrderModel {
  final String id;
  final int? orderToken;
  final String status;
  final String? adminMessage;
  final double? totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UserOrderItemModel> items;
  final bool isCustomOrder;
  final String? purity;
  final String? style;
  final String? marking;
  final List<String> referenceImages;
  final String? partyCode;
  final String? partyName;
  final String? area;
  final String? contactNumber;
  final String? itemName;
  final String? weight;
  final String? noOfPieces;
  final String? size;
  final String? lengthBroadness;
  final String? productDescription;
  final String? assignedKarigar;
  final String? talkedToStaffName;
  final String? assignAdminNotes;
  final String? completeAdminNotes;
  final DateTime? deliveryDate;

  UserOrderModel({
    required this.id,
    required this.orderToken,
    required this.status,
    required this.adminMessage,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.isCustomOrder = false,
    this.purity,
    this.style,
    this.marking,
    this.referenceImages = const [],
    this.partyCode,
    this.partyName,
    this.area,
    this.contactNumber,
    this.itemName,
    this.weight,
    this.noOfPieces,
    this.size,
    this.lengthBroadness,
    this.productDescription,
    this.assignedKarigar,
    this.talkedToStaffName,
    this.assignAdminNotes,
    this.completeAdminNotes,
    this.deliveryDate,
  });

  factory UserOrderModel.fromJson(Map<String, dynamic> json) {
    final isCustom = json["isCustomOrder"] ?? json["isCustom"] ?? false;
    return UserOrderModel(
      id: json["id"]?.toString() ?? '',
      orderToken: json["orderToken"],
      status: json["status"]?.toString() ?? '',
      adminMessage: json["adminMessage"]?.toString(),
      totalAmount: json["totalAmount"] != null
          ? double.tryParse(json["totalAmount"].toString())
          : null,
      createdAt: DateTime.tryParse(json["createdAt"]?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json["updatedAt"]?.toString() ?? '') ??
          DateTime.now(),
      items: json["items"] != null
          ? List<UserOrderItemModel>.from(
              (json["items"] as List).map(
                (e) => UserOrderItemModel.fromJson(e),
              ),
            )
          : [],
      isCustomOrder: isCustom,
      purity: json["purity"]?.toString(),
      style: json["style"]?.toString(),
      marking: json["marking"]?.toString(),
      referenceImages: json["referenceImages"] != null
          ? List<String>.from(
              (json["referenceImages"] as List).map((e) => e.toString()))
          : [],
      partyCode: json["partyCode"]?.toString(),
      partyName: json["partyName"]?.toString(),
      area: json["area"]?.toString(),
      contactNumber: json["contactNumber"]?.toString(),
      itemName: json["itemName"]?.toString(),
      weight: json["weight"]?.toString(),
      noOfPieces: json["noOfPieces"]?.toString(),
      size: json["size"]?.toString(),
      lengthBroadness: json["lengthBroadness"]?.toString(),
      productDescription: json["productDescription"]?.toString(),
      assignedKarigar: json["assignedKarigar"]?.toString(),
      talkedToStaffName: json["talkedToStaffName"]?.toString(),
      assignAdminNotes: json["assignAdminNotes"]?.toString(),
      completeAdminNotes: json["completeAdminNotes"]?.toString(),
      deliveryDate: json["deliveryDate"] != null
          ? DateTime.tryParse(json["deliveryDate"].toString())
          : null,
    );
  }
}

class UserOrderItemModel {
  final String id;
  final int quantity;
  final double price;
  final bool isRejected;
  final String? stockNote;
  final UserOrderProductModel product;

  UserOrderItemModel({
    required this.id,
    required this.quantity,
    required this.price,
    required this.isRejected,
    required this.stockNote,
    required this.product,
  });

  factory UserOrderItemModel.fromJson(Map<String, dynamic> json) {
    return UserOrderItemModel(
      id: json["id"]?.toString() ?? '',
      quantity: json["quantity"] ?? 0,
      price: double.tryParse(json["price"].toString()) ?? 0,
      isRejected: json["isRejected"] ?? false,
      stockNote: json["stockNote"]?.toString(),
      product: UserOrderProductModel.fromJson(json["product"] ?? {}),
    );
  }
}

class UserOrderProductModel {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final String? imageUrl;
  final String? tagNo;
  final String? karat;
  final double? karigarNetWt;
  final double? karigarFineWt;
  final String? size1;

  UserOrderProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    this.imageUrl,
    this.tagNo,
    this.karat,
    this.karigarNetWt,
    this.karigarFineWt,
    this.size1,
  });

  factory UserOrderProductModel.fromJson(Map<String, dynamic> json) {
    return UserOrderProductModel(
      id: json["id"]?.toString() ?? '',
      name: json["name"]?.toString() ?? '',
      slug: json["nameSlug"]?.toString() ?? json["slug"]?.toString() ?? '',
      isActive: json["isActive"] ?? false,
      imageUrl: json["imageUrl"],
      tagNo: json["tagNo"]?.toString(),
      karat: json["karat"]?.toString(),
      karigarNetWt: json["karigarNetWt"] != null
          ? double.tryParse(json["karigarNetWt"].toString())
          : null,
      karigarFineWt: json["karigarFineWt"] != null
          ? double.tryParse(json["karigarFineWt"].toString())
          : null,
      size1: json["size1"]?.toString(),
    );
  }

  String? get displayImageUrl => imageUrl;
}