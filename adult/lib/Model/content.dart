class ContentModel {
  final String title;
  final String type;
  final String fileUrl;
  final int id;
  final int institutionId;
  final int subjectId;
  ContentModel({
    required this.title,
    required this.type,
    required this.fileUrl,
    required this.id,
    required this.institutionId,
    required this.subjectId,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      type: json['type'] ?? 'unknown',
      fileUrl: json['fileUrl'] ?? '',
      institutionId: json['institutionId'],
      subjectId: json['subjectId'],
    );
  }
}
