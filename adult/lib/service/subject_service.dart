import 'dart:convert';
import '../Model/subject_model.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:adult/service/api_config.dart';

class subjectService {
  final String baseUrl = '$kBackendHost/api/subject';
  final Database? db;

  subjectService({this.db});

  Future<List<subjectModel>> getSubjectsByProgramme(int programmeId) async {
    if (db != null) {
      print('📦 Loading subjects from local storage...');
      return await _getSubjectsOffline(programmeId);
    }
    print('🌐 No local db — fetching from server...');
    return await _getSubjectsOnline(programmeId);
  }

  Future<List<subjectModel>> _getSubjectsOffline(int programmeId) async {
    final results = await db!.query(
      'subjects',
      where: 'programmeId = ?', // ← filter by programmeId
      whereArgs: [programmeId],
    );
    print('📦 Found ${results.length} subjects for programme $programmeId');
    return results
        .map(
          (row) => subjectModel(
            id: row['id'] as int,
            name: row['courseName'] as String? ?? '',
            code: row['CourseCode'] as String? ?? '',
            description: row['description'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<List<subjectModel>> _getSubjectsOnline(int programmeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/programme/$programmeId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => subjectModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }
}
