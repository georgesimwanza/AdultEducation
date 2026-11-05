/// A notification to show at a set time.
class Reminder {
  final DateTime at;
  final String title;
  final String body;
  const Reminder({required this.at, required this.title, required this.body});
}
