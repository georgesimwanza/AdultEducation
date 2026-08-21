class AnnouncementModel {
  final int id;
  final int programmeId;
  final int institutionId;
  final String title;
  final String content;

  AnnouncementModel({
    required this.id,
    required this.programmeId,
    required this.institutionId,
    required this.title,
    required this.content,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? 0,
      programmeId: json['programme']?['id'] ?? json['programmeId'] ?? 0,
      institutionId: json['institution']?['id'] ?? json['institutionId'] ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'programmeId': programmeId,
      'title': title,
      'content': content,
    };
  }
}
