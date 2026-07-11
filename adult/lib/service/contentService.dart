import 'package:adult/Model/content.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class contentService {
  final String baseUrl = 'http://10.0.2.2:8080/api/Content';
  final Database? db;
  contentService({this.db});

  Future<List<ContentModel>> getContent(int courseId) async {
    if (db != null) {
      print('📦 Loading content from local storage...');
      return await _getContentOffline(courseId);
    }
    print('🌐 No local db — fetching from server...');
    return await _getContentOnline(courseId);
  }

  Future<List<ContentModel>> _getContentOffline(int courseId) async {
    final results = await db!.query(
      'content',
      where: 'courseId = ?',
      whereArgs: [courseId],
    );
    print('📦 Found ${results.length} content items in local storage');
    return results
        .map(
          (row) => ContentModel(
            id: row['id'] as int,
            title: row['title'] as String? ?? '',
            type: row['type'] as String? ?? '',
            fileUrl: row['fileUrl'] as String? ?? '',
            institutionId: row['institutionId'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<List<ContentModel>> _getContentOnline(int courseId) async {
    final response = await http.get(Uri.parse('$baseUrl/course/$courseId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ContentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load content');
    }
  }

  Future<List<ContentModel>> getAllContent() async {
    final response = await http.get(Uri.parse('$baseUrl/getAllContent'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ContentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load content');
    }
  }

  Future<void> addContent({
    required String title,
    required String type,
    required String fileUrl,
    required int courseId,
    required int institutionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addContent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'type': type,
        'fileUrl': fileUrl,
        'courseId': courseId,
        'institutionId': institutionId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add content: ${response.body}');
    }
  }
}
