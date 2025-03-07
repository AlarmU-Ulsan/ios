import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String url;

  ApiService({required this.url});

  Future<List<Notice>> fetchNotices() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // UTF-8 디코딩 적용
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedBody);

        if (jsonData["isSuccess"] == false) {
          throw Exception("API 요청 실패: ${jsonData['message']}");
        }

        final List<dynamic> contentList = jsonData["result"]["content"];

        return contentList.map((item) => Notice.fromJson(item)).toList();
      } else {
        throw Exception("HTTP 오류: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("API 오류: $e");
    }
  }
}

class Notice {
  final int id;
  final String title;
  final String date;
  final String link;
  final String type;
  final String major;

  Notice({
    required this.id,
    required this.title,
    required this.date,
    required this.link,
    required this.type,
    required this.major,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'] ?? "제목 없음",
      date: json['date'] ?? "날짜 없음",
      link: json['link'] ?? "링크 없음",
      type: json['type'],
      major: json['major'],
    );
  }
}
