// lib/Service/programme_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/programme_model.dart';
import 'package:adult/service/api_config.dart';

class ProgrammeService {
  final String baseUrl = '$kBackendHost/api/programmes';

  Future<List<ProgrammeModel>> getProgrammes() async {
    final response = await http.get(Uri.parse('$baseUrl/allProgrammes'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProgrammeModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load programmes');
    }
  }
}
