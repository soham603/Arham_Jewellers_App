class AncillaryPageModel {
  final String title;
  final String content;

  const AncillaryPageModel({
    required this.title,
    required this.content,
  });

  factory AncillaryPageModel.fromJson(Map<String, dynamic> json) {
    return AncillaryPageModel(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }


}
