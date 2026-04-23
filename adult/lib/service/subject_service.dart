import 'dart:convert';
import '../Model/subject_model.dart';
import 'package:http/http.dart' as http;

class subjectService {
  final String baseUrl = 'http://10.0.2.2:8080/api/subject';

  Future<List<subjectModel>> getSubjectsByProgramme(programmeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/programme/$programmeId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => subjectModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load subjects");
    }
  }
}
