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
    // 1. Try rawData (SalesTouch / Touch)
    final raw = rawData?['SalesTouch']?.toString().trim() ??
                rawData?['Touch']?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      final result = _resolvePurity(raw);
      if (result != null) return result;
    }

    // 2. Fallback: extract purity from tagNo prefix (e.g. "76GR-303" → "76")
    if (tagNo != null && tagNo!.length >= 2) {
      final result = _resolvePurity(tagNo!.substring(0, 2));
      if (result != null) return result;
    }

    // 3. Fallback: karat field (e.g. "22", "22K")
    if (karat != null) {
      final result = _resolveKarat(karat!);
      if (result != null) return result;
    }

    // 4. Fallback: extract from product name (e.g. "92", "22K")
    if (name.isNotEmpty) {
      final result = _resolvePurity(name);
      if (result != null) return result;
      final result2 = _resolveKarat(name);
      if (result2 != null) return result2;
    }

    return null;
  }

  static String? _resolvePurity(String raw) {
    final match = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(raw.trim());
    final numStr = match?.group(1);
    if (numStr == null) return null;
    var value = double.tryParse(numStr);
    if (value == null) return null;

    // Normalize to parts-per-thousand scale
    if (value < 1) {
      // Decimal fraction (0.916 → 916)
      value *= 1000;
    } else if (value < 100) {
      // Percentage (91.6 → 916)
      value *= 10;
    }
    value = value.roundToDouble();

    if (value >= 900 && value <= 925) return "$numStr (22 K)";
    if (value >= 820 && value <= 840) return "$numStr (20 K)";
    if (value >= 740 && value <= 760) return "$numStr (18 K)";

    return null;
  }

  /// Maps karat values (18, 20, 22) to their purity strings.
  static String? _resolveKarat(String raw) {
    final match = RegExp(r'(\d+)\s*K', caseSensitive: false).firstMatch(raw.trim());
    final numStr = match?.group(1);
    if (numStr == null) return null;
    final value = int.tryParse(numStr);
    if (value == null) return null;

    switch (value) {
      case 22: return '0.916 (22 K)';
      case 20: return '0.833 (20 K)';
      case 18: return '0.750 (18 K)';
    }
    return null;
  }

  double? get salesTouch {
    final raw = rawData?['SalesTouch']?.toString().trim() ??
                rawData?['Touch']?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
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
