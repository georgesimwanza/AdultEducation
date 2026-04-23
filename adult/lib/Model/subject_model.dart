class subjectModel {
  final String code;
  final String name;
  final String description;

  subjectModel({
    required this.code,
    required this.name,
    required this.description,
  });

  factory subjectModel.fromJson(Map<String, dynamic> json) {
    return subjectModel(
      code: json['courseCode'] ?? '', // lowercase c
      name: json['courseName'] ?? '', // lowercase c
      description: json['description'] ?? '',
    );
  }
}
