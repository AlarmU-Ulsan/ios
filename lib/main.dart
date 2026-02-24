import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'splashScreen.dart';

/// 전역 플러그인 (로컬 알림)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// iOS 로컬 알림 권한 요청
Future<void> requestLocalNotificationPermissions() async {
  final iosImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  if (iosImplementation != null) {
    await iosImplementation.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

/// ✅ 부팅 시 SharedPreferences 상태 확인 (디버그용)
Future<void> debugPrefsAtBoot() async {
  final prefs = await SharedPreferences.getInstance();
  debugPrint('🔎 [BOOT] keys=${prefs.getKeys()}');
  debugPrint('🔎 [BOOT] hasSeenIntro=${prefs.getBool("hasSeenIntro")}');
}

Future<void> _initLocalNotifications() async {
  const initializationSettings = InitializationSettings(
    iOS: DarwinInitializationSettings(),
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> _requestFcmPermissions() async {
  final settings = await FirebaseMessaging.instance.requestPermission();
  debugPrint('🔔 FCM 권한 상태: ${settings.authorizationStatus}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 디버그 모드에서만 prefs 로그 출력(원하면 조건 제거 가능)
  if (kDebugMode) {
    await debugPrefsAtBoot();
  }

  // 로컬 알림 초기화
  await _initLocalNotifications();

  // iOS 로컬 알림 권한 요청
  await requestLocalNotificationPermissions();

  // FCM 권한 요청
  await _requestFcmPermissions();

  runApp(const NotificationIT());
}

class NotificationIT extends StatelessWidget {
  const NotificationIT({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '알림IT',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashScreen(), // ✅ 앱 시작은 항상 스플래시
    );
  }
}