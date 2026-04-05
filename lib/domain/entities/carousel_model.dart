class CarouselModel {
  final String id;
  final String title;
  final String description;
  final String? descHtml;
  final String imageUrl;
  final String? mobileImageUrl;
  final String? linkUrl;
  final int position;
  final bool isActive;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  final DateTime? deletedAt;
  final String? deletedBy;

  final String? imagePublicId;

  CarouselModel({
    required this.id,
    required this.title,
    required this.description,
    this.descHtml,
    required this.imageUrl,
    this.mobileImageUrl,
    this.linkUrl,
    required this.position,
    required this.isActive,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.imagePublicId,
  });

  factory CarouselModel.fromJson(Map<String, dynamic> json) {
    return CarouselModel(
      id: json['id'] ?? "",
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      descHtml: json['descHtml'],

      imageUrl: json['imageUrl'] ?? "",
      mobileImageUrl: json['mobileImageUrl'],
      linkUrl: json['linkUrl'],

      position: json['position'] ?? 0,
      isActive: json['isActive'] ?? false,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      createdBy: json['createdBy'],

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      updatedBy: json['updatedBy'],

      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'])
          : null,
      deletedBy: json['deletedBy'],

      imagePublicId: json['imagePublicId'],
    );
  }
}
