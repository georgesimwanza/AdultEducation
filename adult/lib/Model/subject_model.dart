class subjectModel {
  final int id;
  final String code;
  final String name;
  final String description;

  subjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
  });

  factory subjectModel.fromJson(Map<String, dynamic> json) {
    print('>>> subjectModel JSON: $json');
    return subjectModel(
      id: json['id'] ?? json['courseId'] ?? 0, // try common key names
      code: json['CourseCode'] ?? json['courseCode'] ?? '', // fix casing
      name: json['courseName'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
