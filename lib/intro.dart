import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'init_selecet_page.dart';
import 'consent_manager.dart'; // ✅ 공통 ConsentManager 사용

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  IntroPageState createState() => IntroPageState();
}

class IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      // 👉 기존 clear()는 유지 여부 고민 필요 (앱 첫 실행이면 O, 아니면 데이터 날려버리니 위험)
      await prefs.clear();

      final consented = await ConsentManager.isConsented();

      if (!consented && mounted) {
        // 아직 동의하지 않은 경우: 시트 표시
        final result = await ConsentManager.showPrivacyConsentSheet(context);

        if (result == true) {
          // ✅ 동의
          await ConsentManager.setConsented(true);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const InitSelectPage1(skipSecond: false),
            ),
          );
        } else {
          // ❌ 닫기
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const InitSelectPage1(skipSecond: true),
            ),
          );
        }
      } else {
        // 이미 동의한 사용자 → 2단계까지 진행
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const InitSelectPage1(skipSecond: false),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          const Spacer(),
          Column(
            children: [
              const Spacer(),
              SvgPicture.asset('assets/icons/알림it_icon.svg', width: 60, height: 60),
              const SizedBox(height: 10),
              const Text(
                '알림IT',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}