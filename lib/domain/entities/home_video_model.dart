class HomeVideoModel {
  final String id;
  final String videoUrl;
  final String? videoPublicId;
  final bool isActive;
  final String? linkType;
  final String? linkId;
  final String? linkRef;
  final String? linkName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? updatedByName;

  HomeVideoModel({
    required this.id,
    required this.videoUrl,
    this.videoPublicId,
    required this.isActive,
    this.linkType,
    this.linkId,
    this.linkRef,
    this.linkName,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
  });

  bool get hasLink =>
      linkType != null &&
      linkType!.isNotEmpty &&
      linkType!.toLowerCase() != 'none';

  factory HomeVideoModel.fromJson(Map<String, dynamic> json) {
    return HomeVideoModel(
      id: json['id'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      videoPublicId: json['videoPublicId'],
      isActive: json['isActive'] ?? false,
      linkType: json['linkType'],
      linkId: json['linkId'],
      linkRef: json['linkRef'],
      linkName: json['linkName'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      updatedBy: json['updatedBy'],
      updatedByName: json['updatedByName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'videoPublicId': videoPublicId,
      'isActive': isActive,
      'linkType': linkType,
      'linkId': linkId,
      'linkRef': linkRef,
      'linkName': linkName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
    };
  }
}
