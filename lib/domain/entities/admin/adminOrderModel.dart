class AdminOrderModel {
  final String id;
  final String status;
  final String? adminMessage;
  final double? totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCustom;

  final AdminOrderUserModel user;
  final List<AdminOrderItemModel> orderItems;

  // Custom order fields
  final String? productId;
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
  final String? purity;
  final String? style;
  final String? marking;
  final List<String> referenceImages;
  final String? assignedKarigarId;
  final String? assignedKarigarName;
  final String? talkedToStaffName;
  final String? assignAdminNotes;
  final String? completeAdminNotes;
  final String? deliveryDate;
  final bool isCustomOrder;

  AdminOrderModel({
    required this.id,
    required this.status,
    required this.adminMessage,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.isCustom,
    required this.user,
    required this.orderItems,
    this.productId,
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
    this.purity,
    this.style,
    this.marking,
    this.referenceImages = const [],
    this.assignedKarigarId,
    this.assignedKarigarName,
    this.talkedToStaffName,
    this.assignAdminNotes,
    this.completeAdminNotes,
    this.deliveryDate,
    this.isCustomOrder = false,
  });

  factory AdminOrderModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminOrderModel(
      id: json["id"] ?? "",

      status: json["status"] ?? "",

      adminMessage: json["adminMessage"],

      totalAmount:
          json["totalAmount"] != null
              ? double.tryParse(
                    json["totalAmount"].toString(),
                  ) ??
                  0
              : null,

      createdAt: DateTime.tryParse(
            json["createdAt"]?.toString() ?? '',
          ) ??
          DateTime.now(),

      updatedAt: DateTime.tryParse(
            json["updatedAt"]?.toString() ?? '',
          ) ??
          DateTime.now(),

      isCustom: json["isCustomOrder"] ?? json["isCustom"] ?? false,

      user: AdminOrderUserModel.fromJson(
        json["user"] ?? {},
      ),

      orderItems:
          json["orderItems"] != null
              ? List<AdminOrderItemModel>.from(
                json["orderItems"].map(
                  (x) =>
                      AdminOrderItemModel.fromJson(x),
                ),
              )
              : [],

      // Custom order fields
      productId: json["productId"]?.toString(),
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
      purity: json["purity"]?.toString(),
      style: json["style"]?.toString(),
      marking: json["marking"]?.toString(),
      referenceImages: json["referenceImages"] != null
          ? List<String>.from(
              (json["referenceImages"] as List).map((e) => e.toString()))
          : [],
      assignedKarigarId: json["assignedKarigarId"]?.toString(),
      assignedKarigarName: json["assignedKarigarName"]?.toString(),
      talkedToStaffName: json["talkedToStaffName"]?.toString(),
      assignAdminNotes: json["assignAdminNotes"]?.toString(),
      completeAdminNotes: json["completeAdminNotes"]?.toString(),
      deliveryDate: json["deliveryDate"]?.toString(),
      isCustomOrder: json["isCustomOrder"] ?? false,
    );
  }
}


// USER MODEL


class AdminOrderUserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String companyName;
  final String city;

  AdminOrderUserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.companyName,
    required this.city,
  });

  factory AdminOrderUserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminOrderUserModel(
      id: json["id"] ?? "",

      name: json["name"] ?? "",

      phoneNumber:
          json["phoneNumber"] ?? "",

      companyName:
          json["companyName"] ?? "",

      city: json["city"] ?? "",
    );
  }
}


// ORDER ITEM MODEL


class AdminOrderItemModel {
  final String id;
  final String orderId;
  final String productId;

  final int quantity;
  final double price;

  final String stockNote;
  final bool isRejected;

  final AdminOrderProductModel product;

  AdminOrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.stockNote,
    required this.isRejected,
    required this.product,
  });

  factory AdminOrderItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminOrderItemModel(
      id: json["id"] ?? "",

      orderId: json["orderId"] ?? "",

      productId: json["productId"] ?? "",

      quantity: json["quantity"] ?? 0,

      price:
          double.tryParse(
            json["price"].toString(),
          ) ??
          0,

      stockNote:
          json["stockNote"] ?? "",

      isRejected:
          json["isRejected"] ?? false,

      product:
          AdminOrderProductModel.fromJson(
            json["product"] ?? {},
          ),
    );
  }
}

class AdminOrderProductModel {
  final String id;
  final String name;
  final String? imageUrl;
  final Map<String, dynamic>? rawData;

  AdminOrderProductModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.rawData,
  });

  factory AdminOrderProductModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminOrderProductModel(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      imageUrl: json["imageUrl"],
      rawData: json["rawData"] != null
          ? Map<String, dynamic>.from(json["rawData"])
          : null,
    );
  }

  String? get displayImageUrl => imageUrl;

  double? get netWeight {
    final value = rawData?['NetWt'];
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  double? get fineWeight {
    final value = rawData?['FineWt'];
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  String? get size {
    final value = rawData?['Size1'];
    if (value == null) return null;
    return value.toString();
  }
}