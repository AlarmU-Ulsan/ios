import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:notification_it/keyword.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
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
                  style: TextStyle(color: Color(0xff009D72), fontWeight: FontWeight.bold),
                )))
      ],
    );
  }

  Widget Selector(String major) {
    return Container(
      margin: EdgeInsets.only(top: 30),
      child: Row(
        children: [
          Text(
            major,
            style: TextStyle(fontSize: 17),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                if(_isSelectedList.contains(major)){
                  _unsubscribeMajor(major);
                  _isSelectedList.remove(major);
                } else {
                  _isSelectedList.add(major);
                  _subscribeMajor(major);
                }
                _saveSelectedMajors();
              });
            },
            child: _isSelectedList.contains(major)
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

  Future<void> _subscribeMajor(String major) async {
    String deviceId = widget.deviceId;

    final ApiService apiService = ApiService(url: "https://alarm-it.ulsan.ac.kr:$port/fcm/subscribe");

    try {
      // ✅ API 호출 및 응답 수신
      final response = await apiService.subscribeNotice(deviceId, major);
      final message = response['message'] ?? '응답 메시지가 없습니다.';
      print("📨 서버 응답: $message");

    } catch (e) {
      print("❌ 오류 발생: $e");
    }
  } //전공 구독
  Future<void> _unsubscribeMajor(String major) async {
    String deviceId = widget.deviceId;

    final ApiService apiService = ApiService(url: "https://alarm-it.ulsan.ac.kr:$port/fcm/subscribe");

    try {
      // ✅ API 호출 및 응답 수신
      final response = await apiService.unsubscribeNotice(deviceId, major);

    } catch (e) {
      print("❌ 오류 발생: $e");
    }
  } //전공 삭제

  void _saveSelectedMajors() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('alram_list', _isSelectedList);
  }

  void _loadSelectedMajoirs() async{
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('alram_list') ?? [];
    setState(() {
      _isSelectedList = saved.toList();
    });
  }

  void _saveAlarmState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isAllAlarmOn", value);
  }

  void _loadAlarmState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool("isAllAlarmOn") ?? true; // 기본값 true
    setState(() {
      _isChecked = saved;
    });
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Center(
                child: Text(
                  '알림설정',
                  style: TextStyle(
                      color: Color(0xff009D72),
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                height: 3,
                color: Color(0xff009D72),
              )
            ],
          ),
        ),
         Expanded(
          child: Column(
            children: [
              Center(
                child: Text(
                  '',
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                height: 2,
                color: Color(0xffA3A3A3),
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState(){
    super.initState();
    _loadSelectedMajoirs();
    _loadAlarmState();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 뒤로가기 + 스위치
          Container(
            padding: EdgeInsets.fromLTRB(30, 80, 30, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios_new_sharp, size: 20),
                      SizedBox(width: 5),
                      Text(
                        '알림 설정',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                CupertinoSwitch(
                  value: _isChecked,
                  activeColor: Color(0xFF009D72),
                  onChanged: (bool? value) async {
                    setState(() {
                      _isChecked = value ?? false;
                    });

                    _saveAlarmState(_isChecked);

                    if (_isChecked) {
                      showNotification('알림이 설정되었습니다');
                      // 전체 구독
                      for (String major in _isSelectedList) {
                        try {
                          await _subscribeMajor(major);
                        } catch (e) {
                          print("❌ $major 구독 실패: $e");
                        }
                      }
                    } else {
                      showNotification('알림이 해제되었습니다');
                      // 전체 구독 해제
                      for (String major in _isSelectedList) {
                        try {
                          await _unsubscribeMajor(major);
                        } catch (e) {
                          print("❌ $major 구독 해제 실패: $e");
                        }
                      }
                    }
                  },
                )
              ],
            ),
          ),
          SizedBox(height: 30),
          _header(),
          //if (!_iskeyword)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    SearchForm(),
                    Container(height: 2, color: Color(0xff009D72)),
                    SizedBox(height: 40),
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
          /*
          if(_iskeyword)
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/알림it_bell_O.svg',
                    ),
                    SizedBox(width: 15,),
                    Text('알림 받는 키워드 n개', style: TextStyle(fontWeight: FontWeight.bold),),
                    Spacer(),
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>KeywordPage()));
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Color(0xffEEEEEE),
                        ),
                        child: Text('키워드 설정'),
                      ),
                    )
                  ],
                ),
              )
            ],
          ))*/
        ],
      ),
    );
  }
}
