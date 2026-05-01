import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/schedule_model.dart';

class ScheduleService {
  static const String _base = 'http://10.0.2.2:8080/api';

  Future<ScheduleEntry> createSchedule(ScheduleEntry entry) async {
    final response = await http.post(
      Uri.parse('$_base/schedules'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ScheduleEntry.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to save schedule: ${response.statusCode}');
  }


  Future<List<ScheduleEntry>> fetchSchedules(String email) async {
    final response = await http.get(
      Uri.parse('$_base/schedules?email=${Uri.encodeComponent(email)}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ScheduleEntry.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch schedules: ${response.statusCode}');
  }

  // DELETE /schedules/{id} — delete a schedule
  Future<void> deleteSchedule(String id) async {
    final response = await http.delete(Uri.parse('$_base/schedules/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete schedule: ${response.statusCode}');
    }
  }
}
