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
    );
  }
}