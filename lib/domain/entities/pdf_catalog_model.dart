class PdfCatalogPageModel {
  final String id;
  final int pageNumber;
  final String imageUrl;
  final int width;
  final int height;
  final bool isActive;

  PdfCatalogPageModel({
    required this.id,
    required this.pageNumber,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.isActive = true,
  });

  factory PdfCatalogPageModel.fromJson(Map<String, dynamic> json) {
    return PdfCatalogPageModel(
      id: json['id']?.toString() ?? '',
      pageNumber: int.tryParse(json['pageNumber']?.toString() ?? '') ?? 1,
      imageUrl: json['imageUrl']?.toString() ?? '',
      width: int.tryParse(json['width']?.toString() ?? '') ?? 0,
      height: int.tryParse(json['height']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  PdfCatalogPageModel copyWith({bool? isActive}) {
    return PdfCatalogPageModel(
      id: id,
      pageNumber: pageNumber,
      imageUrl: imageUrl,
      width: width,
      height: height,
      isActive: isActive ?? this.isActive,
    );
  }
}

class PdfCatalogModel {
  final String id;
  final String title;
  final int pageCount;
  final bool isActive;
  final List<PdfCatalogPageModel> pages;

  PdfCatalogModel({
    required this.id,
    required this.title,
    required this.pageCount,
    this.isActive = true,
    required this.pages,
  });

  factory PdfCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];
    return PdfCatalogModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Catalog',
      pageCount: int.tryParse(json['pageCount']?.toString() ?? '') ??
          (rawPages is List ? rawPages.length : 0),
      isActive: json['isActive'] ?? true,
      pages: rawPages is List
          ? rawPages
              .map((e) =>
                  PdfCatalogPageModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  PdfCatalogModel copyWith({List<PdfCatalogPageModel>? pages}) {
    return PdfCatalogModel(
      id: id,
      title: title,
      pageCount: pageCount,
      isActive: isActive,
      pages: pages ?? this.pages,
    );
  }
}

class CatalogDesignSelection {
  final String catalogId;
  final String catalogTitle;
  final String pageId;
  final int pageNumber;
  final String imageUrl;
  final int width;
  final int height;
  final double x;
  final double y;

  const CatalogDesignSelection({
    required this.catalogId,
    required this.catalogTitle,
    required this.pageId,
    required this.pageNumber,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
  });

  factory CatalogDesignSelection.fromJson(Map<String, dynamic> json) {
    return CatalogDesignSelection(
      catalogId: json['catalogId']?.toString() ?? '',
      catalogTitle: json['catalogTitle']?.toString() ?? '',
      pageId: json['pageId']?.toString() ?? '',
      pageNumber: int.tryParse(json['pageNumber']?.toString() ?? '') ?? 1,
      imageUrl: json['imageUrl']?.toString() ?? '',
      width: int.tryParse(json['width']?.toString() ?? '') ?? 0,
      height: int.tryParse(json['height']?.toString() ?? '') ?? 0,
      x: double.tryParse(json['x']?.toString() ?? '') ?? 0,
      y: double.tryParse(json['y']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        'catalogTitle': catalogTitle,
        'pageId': pageId,
        'pageNumber': pageNumber,
        'imageUrl': imageUrl,
        'width': width,
        'height': height,
        'x': x,
        'y': y,
      };
}
