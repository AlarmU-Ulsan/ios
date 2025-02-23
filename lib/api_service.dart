import 'dart:convert';
import 'package:http/http.dart' as http;
import 'GET_notice.dart';

class ApiService {
  static Future<List<Notice>> fetchNotices() async {
    final response = await http.get(Uri.parse('https://your-api-endpoint.com'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> content = data['result']['content'];
      return content.map((e) => Notice.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notices');
    }
  }
}