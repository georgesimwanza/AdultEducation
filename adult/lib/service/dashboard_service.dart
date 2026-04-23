import 'package:http/http.dart' as http;

class DashboardService {
  final String baseUrl = 'http://10.0.2.2:8080/api/programmes';

  Future<String> getProgramTitle(int id) async {
    // ← add int id here
    final response = await http.get(Uri.parse('$baseUrl/$id/title'));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load title');
    }
  }
}
