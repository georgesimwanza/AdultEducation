class ScheduleEntry {
  final String? id;
  final String title;
  final String userEmail;
  final DateTime date;
  final String startTime; 
  final String endTime; 
  ScheduleEntry({
    this.id,
    required this.title,
    required this.userEmail,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'userEmail': userEmail,
      'date': date.toIso8601String().split('T').first,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id']?.toString(),
      title: json['title'],
      userEmail: json['userEmail'],
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}
