// lib/domain/entities/userOrderModel.dart

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

  UserOrderProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    this.imageUrl,
  });

  factory UserOrderProductModel.fromJson(Map<String, dynamic> json) {
    return UserOrderProductModel(
      id: json["id"]?.toString() ?? '',
      name: json["name"]?.toString() ?? '',
      slug: json["slug"]?.toString() ?? '',
      isActive: json["isActive"] ?? false,
      imageUrl: json["imageUrl"],
    );
  }

  String? get displayImageUrl => imageUrl;
}