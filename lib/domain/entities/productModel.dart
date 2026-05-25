import 'category_model.dart';

class ProductModel {
  final String id;
  final String? tagId;
  final String? tagNo;
  final String name;
  final String? nameSlug;
  final String? imageUrl;
  final String? karat;
  final bool isActive;

  /// Dynamic raw stock/tag data
  final Map<String, dynamic>? rawData;

  /// Category
  final CategoryModel? category;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? createdBy;
  final String? updatedBy;

  ProductModel({
    required this.id,
    this.tagId,
    this.tagNo,
    required this.name,
    this.nameSlug,
    this.imageUrl,
    this.karat,
    required this.isActive,
    this.rawData,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? "",

      tagId: json['tagId']?.toString(),

      tagNo: json['tagNo'],

      name: json['name'] ?? "",

      nameSlug: json['nameSlug'],

      imageUrl: json['imageUrl'],

      karat: json['karat'],

      isActive: json['isActive'] ?? false,

      rawData: json['rawData'] != null
          ? Map<String, dynamic>.from(json['rawData'])
          : null,

      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,

      createdBy: json['createdBy'],

      updatedBy: json['updatedBy'],
    );
  }

  // =========================================================
  // TO JSON
  // =========================================================

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "tagId": tagId,
      "tagNo": tagNo,
      "name": name,
      "nameSlug": nameSlug,
      "imageUrl": imageUrl,
      "karat": karat,
      "isActive": isActive,
      "rawData": rawData,
      "category": category,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "createdBy": createdBy,
      "updatedBy": updatedBy,
    };
  }

  // =========================================================
  // COPY WITH
  // =========================================================

  ProductModel copyWith({
    String? id,
    String? tagId,
    String? tagNo,
    String? name,
    String? nameSlug,
    String? imageUrl,
    String? karat,
    bool? isActive,
    Map<String, dynamic>? rawData,
    CategoryModel? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      tagId: tagId ?? this.tagId,
      tagNo: tagNo ?? this.tagNo,
      name: name ?? this.name,
      nameSlug: nameSlug ?? this.nameSlug,
      imageUrl: imageUrl ?? this.imageUrl,
      karat: karat ?? this.karat,
      isActive: isActive ?? this.isActive,
      rawData: rawData ?? this.rawData,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  String? get touch {
    final value = rawData?['SalesTouch'];

    if (value == null) return null;

    final karat = value.toString() == "92"
        ? "22 K"
        : value.toString() == "84"
        ? "20 K"
        : "18 K";

    return "$value ($karat)";
  }

  double? get salesTouch {
    final value = rawData?['SalesTouch'];

    if (value == null) return null;

    return double.tryParse(value.toString());
  }

  double? get grossWeight {
    final value = rawData?['GrossWt'];

    if (value == null) return null;

    return double.tryParse(value.toString());
  }

  double? get fineWeight {
    final value = rawData?['FineWt'];

    if (value == null) return null;

    return double.tryParse(value.toString());
  }

  String? get itemName {
    return rawData?['ItemName'];
  }

  String? get designName {
    return rawData?['DesignName'];
  }

  String? get groupName {
    return rawData?['GroupName'];
  }

  /// Example:
  /// product.subItemName
  String? get subItemName {
    return rawData?['SubItemName'];
  }

  /// Example:
  /// product.barcode
  String? get barcode {
    return rawData?['Barcode']?.toString();
  }

  /// Example:
  /// product.size
  String? get size {
    return rawData?['Size1'];
  }

  /// Example:
  /// product.metalType
  String? get metalType {
    return rawData?['MetalType'];
  }

  /// Example:
  /// product.genderName
  String? get genderName {
    return rawData?['GenderName'];
  }

  /// Example:
  /// product.designCode
  String? get designCode {
    return rawData?['DesignCode'];
  }

  /// Example:
  /// product.stockImage
  String? get stockImage {
    return rawData?['imageurl'];
  }

  /// Example:
  /// product.voucherNo
  String? get voucherNo {
    return rawData?['VoucherNo'];
  }

  /// Example:
  /// product.hsnCode
  String? get hsnCode {
    return rawData?['HSNCode'];
  }

  /// Example:
  /// product.wastagePercent
  double? get wastagePercent {
    final value = rawData?['WastagePrc'];

    if (value == null) return null;

    return double.tryParse(value.toString());
  }

  /// Example:
  /// product.salesWastagePercent
  double? get salesWastagePercent {
    final value = rawData?['SalesWastagePrc'];

    if (value == null) return null;

    return double.tryParse(value.toString());
  }
}
