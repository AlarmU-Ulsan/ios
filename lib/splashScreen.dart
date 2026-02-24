import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'intro.dart';
import 'api_service.dart';
import 'keys.dart';
import 'mainPage.dart'; // port 등이 들어있는 파일이라고 가정

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 그려진 뒤에 부팅 로직 시작(스플래시가 "먼저" 보이게)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boot();
    });
  }

  Future<void> _boot() async {
    // 스플래시 최소 노출 시간(원하면 0~500ms로 줄여도 됨)
    final minSplash = Future.delayed(const Duration(milliseconds: 800));

    // 1) 첫 실행 여부
    final bool isFirst = await _isFirstLaunchAndMarkSeen();

    // 2) 버전 체크(강제 업데이트면 여기서 막히게 됨)
    await _checkVersionAndPrompt(); // 실패해도 계속 진행하도록 내부에서 catch 처리

    // 3) (선택) 초기 데이터 프리로드 — 필요하면 여기에 추가
    // await _preloadData();

    // 스플래시 최소 시간 보장
    await minSplash;

    // 4) 분기 이동
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isFirst ? const IntroPage() : MainPage(),
      ),
    );
  }

  Future<bool> _isFirstLaunchAndMarkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro');

    if (hasSeenIntro != true) {
      // 첫 실행
      await prefs.setBool('hasSeenIntro', true);
      return true;
    }
    return false;
  }

  // ===== 버전 체크 로직 (기존 main.dart에서 Splash로 이동) =====

  Future<void> _checkVersionAndPrompt() async {
    try {
      final api = ApiService(url: port);
      final server = await api.checkAppVersion();

      final pkg = await PackageInfo.fromPlatform();
      String _normalizeVersion(String v) => v.split('+').first.split('-').first;

      final current = _normalizeVersion(pkg.version); // ✅ 현재 버전
      final latest  = _normalizeVersion(server['latestVersion'] as String);
      final minimum = _normalizeVersion(server['minimumVersion'] as String);
      final link    = server['link'] as String;

      // ✅ 로그 추가 (현재/최신/최소)
      debugPrint('📦 [VERSION] current=$current / latest=$latest / minimum=$minimum');

      final bool force = _isLowerThan(current, minimum);
      final bool soft  = !force && _isLowerThan(current, latest);

      // ✅ 강제/권장 여부도 같이 찍고 싶으면(선택)
      debugPrint('🧭 [VERSION] force=$force / soft=$soft');

      if (force || soft) {
        await _showUpdateDialog(
          link: link,
          force: force,
          latest: latest,
          current: current,
        );
      }
    } catch (e) {
      debugPrint("버전 체크 실패: $e");
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

  Future<void> _showUpdateDialog({
    required String link,
    required bool force,
    required String latest,
    required String current,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !force, // 강제 업데이트면 외부 탭으로 닫기 불가
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
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
                Text(
                  '현재: $current  ·  최신: $latest',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff009D72),
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
                    child: const Text(
                      '업데이트',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!force)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('종료', style: TextStyle(fontSize: 16, color: Colors.black)),
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

  // (선택) 프리로드가 필요하면 여기에 추가
  // Future<void> _preloadData() async {
  //   final api = ApiService(url: port);
  //   await api.fetchNotices();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset('assets/icons/알림it_splash_image.svg'),
      ),
    );
  }
}