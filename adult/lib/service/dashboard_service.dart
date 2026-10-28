import 'package:http/http.dart' as http;
import 'package:adult/service/api_config.dart';

class DashboardService {
  final String baseUrl = '$kBackendHost/api/programmes';

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
