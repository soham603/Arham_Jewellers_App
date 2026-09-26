class HomeVideoModel {
  final String id;
  final String videoUrl;
  final String? videoPublicId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? updatedByName;

  HomeVideoModel({
    required this.id,
    required this.videoUrl,
    this.videoPublicId,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
  });

  factory HomeVideoModel.fromJson(Map<String, dynamic> json) {
    return HomeVideoModel(
      id: json['id'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      videoPublicId: json['videoPublicId'],
      isActive: json['isActive'] ?? false,
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
    };
  }
}
