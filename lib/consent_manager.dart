import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'keys.dart';

class ConsentManager {
  static Future<bool> isConsented() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(kConsentKey) ?? false;
  }

  static Future<void> setConsented(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kConsentKey, v);
  }

  /// ✅ 개인정보 동의 팝업
  static Future<bool?> showPrivacyConsentSheet(
      BuildContext context, {
        String policyUrl = 'https://leekuejea.github.io/alarmIT/',
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
                        child: const Text('[자세히보기]', style: TextStyle(fontSize: 18,color: Color(0xff878787))),
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
}