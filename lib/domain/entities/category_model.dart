class CategoryModel {
  final String id;

  final String name;

  final String nameSlug;

  final String? description;

  final String imageUrl;

  final String? imagePublicId;

  final String? boxName;

  final bool isDeleted;

  final bool isActive;

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

  final int count;

  final int countOfIsStockOne;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameSlug,
    this.description,
    required this.imageUrl,
    this.imagePublicId,
    this.boxName,
    required this.isDeleted,
    this.isActive = true,
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
    this.count = 0,
    this.countOfIsStockOne = 0,
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

      isActive: json['isActive'] ?? true,

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

      count: json['count'] ?? 0,

      countOfIsStockOne: json['countOfIsStockOne'] ?? 0,
    );
  }


}
