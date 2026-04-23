// lib/Service/programme_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/programme_model.dart';

class ProgrammeService {
  final String baseUrl = 'http://10.0.2.2:8080/api/programmes';

  Future<List<ProgrammeModel>> getProgrammes() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProgrammeModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load programmes');
    }
  }
}
