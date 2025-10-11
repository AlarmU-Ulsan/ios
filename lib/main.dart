import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'intro.dart';
import 'mainPage.dart';
import 'splashScreen.dart';
import 'init_selecet_page.dart';

/// 전역 플러그인 (푸시 알림)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// iOS 알림 권한 요청
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 로컬 푸시 알림 초기화
  final InitializationSettings initializationSettings = InitializationSettings(
    iOS: DarwinInitializationSettings(),
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  /// iOS 권한 요청
  await requestLocalNotificationPermissions();
  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission();
  print('🔔 권한 상태: ${settings.authorizationStatus}');

  runApp(const NotificationIT());
}

class NotificationIT extends StatelessWidget {
  const NotificationIT({super.key});

  /// 최초 실행 여부 확인
  Future<bool> isFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenIntro') ?? true; // 기본값: true = 최초 실행
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '알림IT',
      theme: ThemeData(primarySwatch: Colors.green),
      home: FutureBuilder<bool>(
        future: isFirstLaunch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(); // 로딩 대기
          }

          /// 최초 실행 → IntroPage
          if (snapshot.data == true) {
            return const IntroPage();
          }

          /// 이후 실행 → Splash → MainPage
          return SplashScreen();
        },
      ),
    );
  }
}