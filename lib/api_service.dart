import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  final String url;

  ApiService({required this.url});
  Future<Map<String, dynamic>> checkAppVersion() async {
    const String platform = "ios";  // 타입 고정
    final String versionUrl = "$url/api/version/$platform";

    print('\n📡 [버전 확인 요청]');
    print('🌐 요청 URL: $versionUrl');

    try {
      final response = await http.get(Uri.parse(versionUrl));

      print("🔵 상태코드: ${response.statusCode}");
      print("📨 응답 바디: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
        json.decode(utf8.decode(response.bodyBytes));

        if (jsonData['isSuccess'] == false) {
          throw Exception("버전 정보 요청 실패: ${jsonData['message']}");
        }

        final result = jsonData['result'];
        final String latest = result['latestVersion'];
        final String minimum = result['minimumVersion'];
        final String link = result['link'];

        print("✅ 최신 버전: $latest / 최소 버전: $minimum");

        return {
          "latestVersion": latest,
          "minimumVersion": minimum,
          "link": link,
        };
      } else {
        throw Exception("HTTP 오류: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("버전 확인 중 오류 발생: $e");
    }
  } //버전 체크
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
  } //공지 불러오기
  Future postFCMToken(String deviceId, String fcmToken) async {
    print('\n📡 [FCM 등록 요청]');
    print('📱 deviceId: $deviceId');
    print('🔑 fcmToken: $fcmToken');

    String fullUrl = "$url?deviceId=$deviceId&fcmToken=$fcmToken";

    final response = await http.post(
      Uri.parse(fullUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "deviceId": deviceId,
        "fcmToken": fcmToken,
      }),
    );

    print("🔵 상태코드: ${response.statusCode}");
    print("📨 응답 바디: ${utf8.decode(response.bodyBytes)}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ FCM 토큰 등록 성공");
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      print("❌ FCM 토큰 등록 실패");
      throw Exception("HTTP 오류: ${response.statusCode}");
    }
  } //fcm 등록
  Future<Map<String, dynamic>> subscribeNotice(String deviceId, String major) async {
    print('\n📡 [전공 구독 요청]');
    print('📱 deviceId: $deviceId');
    print('📘 major: $major');

    try {
      String fullUrl = "$url?deviceId=$deviceId&major=$major";

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "deviceId": deviceId,
          "major": major,
        }),
      );

      print("🔵 상태코드: ${response.statusCode}");
      print("📨 응답 바디: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ 전공 구독 성공");
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        print("❌ 전공 구독 실패");
        throw Exception("HTTP 오류: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 예외 발생: $e");
      throw Exception("API 오류: $e");
    }
  } //공지알람 구독
  Future<void> unsubscribeNotice(String deviceId, String major) async {
    print('\n📡 [전공 구독 해제 요청]');
    print('📱 deviceId: $deviceId');
    print('📘 major: $major');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "deviceId": deviceId,
          "major": major,
        }),
      );

      print("🔵 상태코드: ${response.statusCode}");
      print("📨 응답 바디: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        print("✅ 전공 구독 해제 성공");
      } else {
        print("❌ 전공 구독 해제 실패");
        throw Exception("HTTP 오류: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 예외 발생: $e");
      throw Exception("API 오류: $e");
    }
  } //공지알람 해제
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