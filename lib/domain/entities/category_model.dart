class CategoryModel {
  final String id;

  final String name;

  final String nameSlug;

  final String? description;

  final String imageUrl;

  final String? imagePublicId;

  final String? boxName;

  final bool isDeleted;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  final String? createdBy;

  final String? updatedBy;

  // NEW
  final String? parentId;

  final CategoryModel? parent;

  final List<CategoryModel>? children;

  final int? level;

  final dynamic images;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameSlug,
    this.description,
    required this.imageUrl,
    this.imagePublicId,
    this.boxName,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,

    // NEW
    this.parentId,
    this.parent,
    this.children,
    this.level,
    this.images,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? "",

      name: json['name'] ?? "",

      nameSlug: json['nameSlug'] ?? "",

      description: json['description'],

      imageUrl: json['imageUrl'] ?? "",

      imagePublicId: json['imagePublicId'],

      boxName: json['boxName'],

      isDeleted: json['isDeleted'] ?? false,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,

      createdBy: json['createdBy'],

      updatedBy: json['updatedBy'],

      // NEW
      parentId: json['parentId'],

      parent: json['parent'] != null
          ? CategoryModel.fromJson(json['parent'])
          : null,

      children: json['children'] != null
          ? (json['children'] as List)
                .map((e) => CategoryModel.fromJson(e))
                .toList()
          : null,

      level: json['level'],

      images: json['images'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,

      "name": name,

      "nameSlug": nameSlug,

      "description": description,

      "imageUrl": imageUrl,

      "imagePublicId": imagePublicId,

      "boxName": boxName,

      "isDeleted": isDeleted,

      "createdAt": createdAt?.toIso8601String(),

      "updatedAt": updatedAt?.toIso8601String(),

      "createdBy": createdBy,

      "updatedBy": updatedBy,

      // NEW
      "parentId": parentId,

      "parent": parent?.toJson(),

      "children": children?.map((e) => e.toJson()).toList(),

      "level": level,

      "images": images,
    };
  }
}
