import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// InitSelectPage1 에서 skipSecond(bool) 파라미터를 받도록 구현되어 있어야 합니다.
import 'init_selecet_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  IntroPageState createState() => IntroPageState();
}

class IntroPageState extends State<IntroPage> {
  // ✅ SharedPreferences 키값
  static const String _consentKey = "privacy_consent_v1";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final consented = prefs.getBool(_consentKey) ?? false;

      if (!consented && mounted) {
        // 아직 동의하지 않은 경우: 시트 표시
        final result = await showPrivacyConsentSheet(context);

        if (result == true) {
          // ✅ 동의
          await prefs.setBool(_consentKey, true);
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
        // 이미 동의한 사용자: 2단계까지 진행
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

  /// ✅ 개인정보 동의 시트
  Future<bool?> showPrivacyConsentSheet(
      BuildContext context, {
        String policyUrl = 'https://leekuejea.github.io/alarmIT/', // 개인정보 처리방침 페이지
      }) {
    bool checked = false;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black.withOpacity(0.6),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 30,
                right: 30,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 25),
                  const Text(
                    '알림IT 이용을 위해',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    '동의가 필요해요',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 25,
                        height: 25,
                        child: Checkbox(
                          value: checked,
                          onChanged: (v) => setState(() => checked = v ?? false),
                          shape: const CircleBorder(),
                          side: const BorderSide(color: Color(0xFFBDBDBD)),
                          activeColor: const Color(0xff009D72),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('개인정보 처리 동의', style: TextStyle(fontSize: 18)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.parse(policyUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text('[자세히보기]', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xffE0E0E0)),
                            backgroundColor: const Color(0xffE9E9E9),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('닫기', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:
                            checked ? const Color(0xff009D72) : const Color(0xffBDBDBD),
                            disabledBackgroundColor: const Color(0xffBDBDBD),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: checked ? () => Navigator.pop(ctx, true) : null,
                          child: const Text('다음'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              const Text('알림IT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}