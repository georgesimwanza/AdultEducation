import 'package:adult/Model/content.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class contentService {
  final String baseUrl = 'http://10.0.2.2:8080/api/Content/course';

  Future<List<ContentModel>> getContent(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("PARSED DATA: $data");
      return data.map((json) => ContentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load content');
    }
  }
}
