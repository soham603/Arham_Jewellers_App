class AdminOrderModel {
  final String id;
  final String status;
  final String? adminMessage;
  final double? totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  final AdminOrderUserModel user;
  final List<AdminOrderItemModel> orderItems;

  AdminOrderModel({
    required this.id,
    required this.status,
    required this.adminMessage,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.orderItems,
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

      createdAt: DateTime.parse(
        json["createdAt"],
      ),

      updatedAt: DateTime.parse(
        json["updatedAt"],
      ),

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
    );
  }
}

// =======================================================
// USER MODEL
// =======================================================

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

// =======================================================
// ORDER ITEM MODEL
// =======================================================

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

  AdminOrderProductModel({
    required this.id,
    required this.name,
  });

  factory AdminOrderProductModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminOrderProductModel(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
    );
  }
}