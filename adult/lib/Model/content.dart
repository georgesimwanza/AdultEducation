class ContentModel {
  final String title;
  final String type;
  final String fileUrl;
  final int id;

  ContentModel({
    required this.title,
    required this.type,
    required this.fileUrl,
    required this.id,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      type: json['type'] ?? 'unknown',
      fileUrl: json['file_Url'] ?? '', // ✅ matches exactly what the API returns
    );
  }
}
