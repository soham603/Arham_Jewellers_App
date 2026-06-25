class _Undefined {
  const _Undefined();
}
const _undefined = _Undefined();

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
  final String? mediaType;

  static String? _inferMediaType(String url) {
    final ext = url.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext)) return 'video';
    return 'image';
  }

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
    this.mediaType,
  });

  CarouselModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? position,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    Object? descHtml = _undefined,
    Object? mobileImageUrl = _undefined,
    Object? linkUrl = _undefined,
    Object? imagePublicId = _undefined,
    Object? mediaType = _undefined,
  }) {
    return CarouselModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      descHtml: descHtml == _undefined ? this.descHtml : descHtml as String?,
      mobileImageUrl: mobileImageUrl == _undefined
          ? this.mobileImageUrl
          : mobileImageUrl as String?,
      linkUrl:
          linkUrl == _undefined ? this.linkUrl : linkUrl as String?,
imagePublicId: imagePublicId == _undefined
           ? this.imagePublicId
           : imagePublicId as String?,
      mediaType:
          mediaType == _undefined ? this.mediaType : mediaType as String?,
    );
  }

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
      mediaType: json['mediaType'] ?? _inferMediaType(json['imageUrl'] ?? ''),
    );
  }
}
