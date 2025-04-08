import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

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
  Future<Map<String, dynamic>> postFCMToken(String token, String major) async {
    try {
      // 동적으로 URL을 생성
      String fullUrl = "$url?token=$token&major=$major";

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 적용
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