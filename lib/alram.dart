import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';
import 'consent_manager.dart';
import 'keys.dart';
import 'main.dart';

class AlarmPage extends StatefulWidget {
  final String deviceId;

  AlarmPage({this.deviceId = ''});

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  bool _isChecked = false;

  List<String> _isSelectedList = [];
  String _searchText = '';

  final Map<String, List<String>> majorMap = {
    "미래엔지니어링융합대학": [
      "ICT융합학부",
      '미래모빌리티공학부',
      '신소재·반도체융합학부',
      '전기전자융합학부',
    ],
    '스마트도시융합대학': ['건축·도시환경학부', '디자인융합학부', '스포츠과학부'],
    '경영·공공정책대학': ['경영경제융합학부'],
    '인문예술대학': ['글로벌인문학부', '예술학부'],
    '아산아너스칼리지': ['자율전공학부'],
    "IT융합학부": ["IT융합전공", "AI융합전공"],
  };

  /// ✅ FCM 토큰 등록
  Future<void> _registerFcmTokenIfNeeded() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("📱 FCM Token: $token");
      // 서버에 deviceId + token 등록 로직 필요시 추가
    } catch (e) {
      print("❌ FCM 토큰 등록 실패: $e");
    }
  }

  Widget SearchForm() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: TextFormField(
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: const InputDecoration(
              hintText: "알림 받을 학과를 입력해주세요",
              hintStyle: TextStyle(color: Color(0xffA3A3A3)),
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 5),
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              '검색',
              style: TextStyle(
                color: Color(0xff009D72),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget Selector(String major) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Row(
        children: [
          Text(major, style: const TextStyle(fontSize: 17)),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final consented = await ConsentManager.isConsented();

              // ✅ 개인정보 동의 체크
              if (!consented) {
                final result = await ConsentManager.showPrivacyConsentSheet(context);
                if (result == true) {
                  await ConsentManager.setConsented(true);
                  await _registerFcmTokenIfNeeded();
                } else {
                  return;
                }
              }

              // ✅ 스위치 OFF면, 항목 터치 자체를 막고 싶다면 여기서 return
              // if (!_isChecked) return;

              setState(() {
                if (_isSelectedList.contains(major)) {
                  _isSelectedList.remove(major);
                } else {
                  _isSelectedList.add(major);

                  // 👉 하나라도 선택하면 스위치 자동 ON (원하면 유지)
                  if (!_isChecked) {
                    _isChecked = true;
                    showNotification('알림이 설정되었습니다');
                  }
                }
              });

              // ✅ 저장 + 구독/해제는 setState 바깥에서 await로 처리 (UI 안정)
              await _saveSelectedMajors();

              if (_isSelectedList.contains(major)) {
                await _subscribeMajor(major);
              } else {
                await _unsubscribeMajor(major);
              }

              // ✅ bell on/off 기준 업데이트: 리스트 비었으면 off
              if (!mounted) return;
              setState(() {
                _isChecked = _isSelectedList.isNotEmpty;
              });
            },
            child: _isSelectedList.contains(major)
                ? SvgPicture.asset('assets/icons/알림it_bell_O.svg')
                : SvgPicture.asset('assets/icons/알림it_bell_X.svg'),
          )
        ],
      ),
    );
  }

  Future<void> showNotification(String text) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      '일반 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '알림 설정',
      text,
      notificationDetails,
    );
  }

  Future<void> _subscribeMajor(String major) async {
    final deviceId = widget.deviceId;
    final apiService = ApiService(url: "$port/fcm/subscribe");
    try {
      final response = await apiService.subscribeNotice(deviceId, major);
      print("📨 서버 응답: ${response['message']}");
    } catch (e) {
      print("❌ 오류 발생: $e");
    }
  }

  Future<void> _unsubscribeMajor(String major) async {
    final deviceId = widget.deviceId;
    final apiService = ApiService(url: "$port/fcm/subscribe");
    try {
      await apiService.unsubscribeNotice(deviceId, major);
    } catch (e) {
      print("❌ 오류 발생: $e");
    }
  }

  // ✅ 중요: InitSelectPage2와 같은 키(kAlarmMajorsKey)로 통일
  Future<void> _saveSelectedMajors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kAlarmMajorsKey, _isSelectedList);
  }

  // ✅ 중요: InitSelectPage2에서 저장된 값으로 초기화
  Future<void> _loadFromInitPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAlarmMajors = prefs.getStringList(kAlarmMajorsKey) ?? [];

    if (!mounted) return;
    setState(() {
      _isSelectedList = savedAlarmMajors;
      _isChecked = savedAlarmMajors.isNotEmpty; // ✅ 요구사항: init에서 설정했으면 ON
    });
  }

  @override
  void initState() {
    super.initState();

    // ✅ 동의한 경우에만 init 저장값 반영
    ConsentManager.isConsented().then((consented) async {
      if (consented) {
        await _loadFromInitPrefs();
      } else {
        // ❌ 동의 안 한 경우 → OFF + 선택값 없음 + 저장도 비움
        if (!mounted) return;
        setState(() {
          _isChecked = false;
          _isSelectedList = [];
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(kAlarmMajorsKey, []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> filteredList = [];
    majorMap.forEach((faculty, majors) {
      final matchedMajors = majors.where((m) => m.contains(_searchText)).toList();
      if (matchedMajors.isNotEmpty) {
        filteredList.add(Text(
          faculty,
          style: const TextStyle(
            color: Color(0xff009D72),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ));
        filteredList.addAll(matchedMajors.map((major) => Selector(major)));
        filteredList.add(const SizedBox(height: 60));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(30, 80, 30, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back_ios_new_sharp, size: 20),
                      SizedBox(width: 5),
                      Text(
                        '알림 설정',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: _isChecked,
                  activeColor: const Color(0xFF009D72),
                  onChanged: (bool? value) async {
                    final consented = await ConsentManager.isConsented();

                    // ✅ 동의 안 한 상태에서 켜려는 경우
                    if ((value ?? false) && !consented) {
                      final result =
                      await ConsentManager.showPrivacyConsentSheet(context);
                      if (result == true) {
                        await ConsentManager.setConsented(true);
                        await _registerFcmTokenIfNeeded();
                        setState(() => _isChecked = true);
                        showNotification('알림이 설정되었습니다');

                        // 켜면 현재 선택된 전공들 구독
                        for (String major in _isSelectedList) {
                          await _subscribeMajor(major);
                        }
                      } else {
                        setState(() => _isChecked = false);
                      }
                      return;
                    }

                    // ✅ OFF로 내리는 경우: 전체 해제 + 리스트 비움 + 저장 비움
                    final next = value ?? false;

                    if (!next) {
                      showNotification('알림이 해제되었습니다');

                      for (String major in _isSelectedList) {
                        await _unsubscribeMajor(major);
                      }

                      if (!mounted) return;
                      setState(() {
                        _isChecked = false;
                        _isSelectedList = [];
                      });

                      await _saveSelectedMajors();
                      return;
                    }

                    // ✅ ON으로 켜는 경우: 현재 리스트 구독 (리스트가 비어있으면 그냥 ON만)
                    setState(() => _isChecked = true);
                    showNotification('알림이 설정되었습니다');

                    for (String major in _isSelectedList) {
                      await _subscribeMajor(major);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchForm(),
                  Container(height: 2, color: const Color(0xff009D72)),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: filteredList,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}