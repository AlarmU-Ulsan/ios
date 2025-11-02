import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'intro.dart';
import 'splashScreen.dart';
import 'api_service.dart';
import 'keys.dart';

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

class NotificationIT extends StatefulWidget {
  const NotificationIT({super.key});
  @override
  State<NotificationIT> createState() => _NotificationITState();
}

class _NotificationITState extends State<NotificationIT> {
  late final Future<bool> _firstLaunchFuture;

  @override
  void initState() {
    super.initState();
    _firstLaunchFuture = isFirstLaunch(); // 한 번만 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersionAndPrompt();
    });
  }

  Future<void> _checkVersionAndPrompt() async {
    try {
      final api = ApiService(url: port);
      final server = await api.checkAppVersion();

      final pkg = await PackageInfo.fromPlatform();
      final current = pkg.version; // "1.0.0" 형태

      final latest = server['latestVersion'] as String;
      final minimum = server['minimumVersion'] as String;
      final link = server['link'] as String;

      bool force = _isLowerThan(current, minimum); // 최소 버전보다 낮으면 강제 업데이트
      bool soft  = !force && _isLowerThan(current, latest); // 최신보다 낮으면 권장 업데이트

      if (force || soft) {
        _showUpdateDialog(
          link: link,
          force: force,
          latest: latest,
          current: current,
        );
      }
    } catch (e) {
      debugPrint("버전 체크 실패: $e"); // 실패해도 앱은 계속 진행
    }
  }

  bool _isLowerThan(String a, String b) {
    List<int> pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (pa.length < 3) pa.add(0);
    while (pb.length < 3) pb.add(0);
    for (int i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i] < pb[i];
    }
    return false;
  }
  Future<void> _openStore(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro');
    debugPrint('👀 hasSeenIntro(before): $hasSeenIntro');

    if (hasSeenIntro != true) {
      await prefs.setBool('hasSeenIntro', true);
      final check = prefs.getBool('hasSeenIntro');
      debugPrint('✅ hasSeenIntro(after set): $check');
      return true; // 첫 실행
    }
    return false;  // 이후 실행
  }

  void _showUpdateDialog({
    required String link,
    required bool force,
    required String latest,
    required String current,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !force, // 강제 업데이트면 외부 탭으로 닫기 불가
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '새 버전이 업데이트되었어요!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('현재: $current  ·  최신: $latest',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await _openStore(link);
                      if (force) {
                        // 강제 업데이트의 경우 앱 종료 유도
                        // iOS는 보통 심사 가이드상 종료를 권장하지 않지만,
                        // 요구사항에 맞춰 종료 버튼 흐름을 유지
                        exit(0);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('업데이트',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                if (!force)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('종료', style: TextStyle(fontSize: 16)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => exit(0),
                      child: const Text('종료', style: TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '알림IT',
      theme: ThemeData(primarySwatch: Colors.green),
      home: FutureBuilder<bool>(
        future: _firstLaunchFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return snapshot.data! ? const IntroPage() : SplashScreen();
        },
      ),
    );
  }
}