class UserModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final int? programmeId;
  final String? programmeName;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    this.programmeId,
    this.programmeName,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get status => isActive ? 'active' : 'inactive';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      isActive: json['isActive'] ?? false,
      programmeId: json['programmeId'],
      programmeName: json['programmeName'] ?? '',
    );
  }
}
