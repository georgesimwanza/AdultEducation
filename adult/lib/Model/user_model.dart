class UserModel {
  final String firstName;
  final String lastName;
  final String email;
  final int? programmeId;
  final String? programmeName;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.programmeId,
    this.programmeName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      programmeId: json['programmeId'],
      programmeName: json['programmeName'] ?? '',
    );
  }
}
