class ProgrammeModel {
  final int id;
  final String name;
  final String? description;

  ProgrammeModel({required this.id, required this.name, this.description});

  factory ProgrammeModel.fromJson(Map<String, dynamic> json) {
    return ProgrammeModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
