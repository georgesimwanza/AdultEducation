class AnnouncementModel {
  final String id;
  final String title;
  final String content;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
  });

  /// Factory constructor to securely construct the model from API backend maps
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      // Safely handles alternative MongoDB variations like '_id' or 'id'
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }

  /// Helper tool converting the entity payload back into a map for POST updates
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'content': content};
  }
}
