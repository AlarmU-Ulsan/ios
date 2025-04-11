import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';

import 'api_service.dart';
import 'main.dart';

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  bool _isChecked = false;

  String _isSelected = '';
  String _searchText = '';

  final Map<String, List<String>> majorMap = {
    "미래엔지니어링융합대학": [
      "ICT융합학부",
      '미래모빌리티공학부',
      '에너지화학공학부',
      '신소재·반도체융합학부',
      '전기전자융합학부',
      '바이오매디컬헬스학부'
    ],
    '스마트도시융합대학': ['건축·도시환경학부', '디자인융합학부', '스포츠과학부'],
    '경영·공공정책대학': ['공공인재학부', '경영경제융합학부'],
    '인문예술대학': ['글로벌인문학부', '예술학부'],
    '의과대학': ['의예과[의학과]', '간호학과'],
    '아산아너스칼리지': ['자율전공학부'],
    '울산대학교': ['SW사업단', 'U-STAR'],
    "IT융합학부": ["IT융합전공", "AI융합전공"],
  };

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
            decoration: InputDecoration(
                hintText: "알림 받을 학과를 입력해주세요",
                hintStyle: TextStyle(color: Color(0xffA3A3A3)),
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 5),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none),
          ),
        ),
        Expanded(
            flex: 1,
            child: GestureDetector(
                onTap: () {},
                child: Text(
                  '검색',
                  style: TextStyle(color: Color(0xff009D72)),
                )))
      ],
    );
  }

  Widget Selector(String name) {
    return Container(
      margin: EdgeInsets.only(top: 30),
      child: Row(
        children: [
          Text(
            name,
            style: TextStyle(fontSize: 17),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_isSelected == name) {
                  _isSelected = '';
                } else {
                  _isSelected = name;
                }
              });
            },
            child: _isSelected == name
                ? SvgPicture.asset(
                    'assets/icons/알림it_bell_O.svg',
                  )
                : SvgPicture.asset(
                    'assets/icons/알림it_bell_X.svg',
                  ),
          )
        ],
      ),
    );
  }

  Future<void> showNotification(String text) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'channel_id', // 채널 ID
      '일반 알림', // 채널 이름
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // 알림 ID
      '알림 설정', // 제목
      text,
      notificationDetails,
    );
  }

  String? fcmToken;
  Future<void> _toggleNotification() async {
    if (fcmToken == null) {
      print("⚠️ FCM 토큰이 존재하지 않습니다.");
      return;
    }

    final ApiService apiService = ApiService(url: "http://localhost:8080/fcm/fcm_token");

    // ✅ API 호출 (POST 요청)
    await apiService.postFCMToken(fcmToken!, _isSelected);

    // ✅ UI 업데이트는 setState() 안에서 처리
    setState(() {
      _isChecked = !_isChecked;
    });

    // ✅ 알림 표시
    showNotification(_isChecked ? '알림이 설정되었습니다' : '알림이 해제되었습니다');
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> filteredList = [];
    majorMap.forEach((faculty, majors) {
      // 전공 중 검색 키워드가 포함된 게 있는지 확인
      final matchedMajors =
          majors.where((m) => m.contains(_searchText)).toList();
      if (matchedMajors.isNotEmpty) {
        filteredList.add(Text(faculty,
            style: TextStyle(
                color: Color(0xff009D72),
                fontSize: 12,
                fontWeight: FontWeight.bold)));
        filteredList.addAll(matchedMajors.map((major) => Selector(major)));
        filteredList.add(SizedBox(height: 60));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(30, 80, 30, 25),
        child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(children: [

                        Icon(
                          Icons.arrow_back_ios_new_sharp,
                          size: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          '알림',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      ]),
                    ),
                    Spacer(),
                    CupertinoSwitch(
                      value: _isChecked,
                      activeColor: Color(0xFF009D72),
                      onChanged: (bool? value) {
                        setState(() {
                          if (!_isChecked) {
                            showNotification('알림이 설정되었습니다');
                          } else {
                            showNotification('알림이 해제되었습니다');
                          }
                          _isChecked = !_isChecked;
                        });
                        _toggleNotification();
                      },
                    )
                  ],
                ),
                SizedBox(
                  height: 17,
                ),
                Text('새 공지 알림 전공 변경', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                SizedBox(
                  height: 40,
                ),
                SearchForm(),
                Container(height: 2, color: Color(0xff009D72),),
                SizedBox(height: 40,),
                Expanded(child: ListView(padding: EdgeInsets.zero, children: filteredList))
              ],
            )),
      ),
    );
  }
}
