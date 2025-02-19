import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:notification_it/splashScreen.dart';
import 'package:notification_it/webView.dart';
import 'list_elements.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void requestPermissions() {
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
} //알림 권한 요청

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //로컬 푸시 알림 초기화

  final DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  requestPermissions(); //ios 권한 요청

  runApp(Notification_IT());
}

class Notification_IT extends StatelessWidget {
  const Notification_IT({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '알림it',
      home: SplashScreen(),

    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  BookmarkManager bookmarkManager = BookmarkManager();

  final List<ElementWidget> elements = [
    ElementWidget(
        important: true,
        date: '2024-09-11',
        topic: '★(필독) 2024-2 전공상담ll 안내사항 ★(총 2회 제출 필수)',
        url: 'https://cicweb.ulsan.ac.kr/cicweb/1024?action=view&no=257361',
    ),
    ElementWidget(
        important: true,
        date: '2024-11-06',
        topic: '★필독★ IT융합학부 프로그래밍 경진대회 안내',
        url: 'https://cicweb.ulsan.ac.kr/cicweb/1024?action=view&no=259533',
    ),
    ElementWidget(
        important: false,
        date: '2025-01-21',
        topic: '2025-1학기 수강신청 안내',
        url: 'https://cicweb.ulsan.ac.kr/cicweb/1024?action=view&no=261810',
    )
  ];

  Future<List<ElementWidget>> getBookmarkedElements() async {
    List<ElementWidget> allElements = elements;

    List<String> bookmarkedItems = await bookmarkManager.getBookmarks();

    return allElements.where((element) {
      return bookmarkedItems.contains('${element.date}|${element.topic}');
    }).toList();
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
  } //푸시알림

  static Future<void> printBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(BookmarkManager.bookmarkKey) ?? [];
    print('저장된 북마크 목록: $bookmarks');
  }//북마크 목록 확인

  bool isTextFieldVisible = false; //검색창
  TextEditingController _controller = TextEditingController();

  bool selected_bell = false; //알림
  int selectedIndex = 0; // 전체, 중요 공지, 북마크

  int selectedBSIndex = 0;
  int selectedBSIndex2 = 0;

  String searchQuery = ''; //검색어 저장 변수

  void _toggleBottomSheet() {
    setState(() {
      _isBottomSheetVisible = !_isBottomSheetVisible;
    });
  } //하단 창

  bool _isBottomSheetVisible = false;
  String buttonText = "IT";

  void _updateButtonText(String newText) {
    setState(() {
      buttonText = newText; // 외부 버튼 텍스트 업데이트
    });
  }

  Widget _bellIcon() {
    bool isSelected_bell = selected_bell;
    return IconButton(
      onPressed: () {
        setState(() {
          if (!selected_bell)
            showNotification('알림이 설정되었습니다');
          else
            showNotification('알림이 해제되었습니다');
          selected_bell = !selected_bell;
        });
      },
      icon: isSelected_bell
          ? SvgPicture.asset(
              'assets/icons/알림it_bell_O.svg',
            )
          : SvgPicture.asset(
              'assets/icons/알림it_bell_X.svg',
            ),
      iconSize: 160,
    );
  }

  Widget _allInfoButton() {
    bool isSelected = selectedIndex == 0;

    return SizedBox(
      height: 26.64,
      width: 47.6,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = 0;
            printBookmarks();
          });
        },
        child: SvgPicture.asset(
          isSelected
              ? 'assets/icons/알림it_전체_O.svg'
              : 'assets/icons/알림it_전체_X.svg',
        ),
      ),
    );
  }
  Widget _importantInfoButton() {
    bool isSelected = selectedIndex == 1;

    return SizedBox(
      height: 26.64,
      width: 76.6,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = 1;
            printBookmarks();
          });
        },
        child: SvgPicture.asset(
          isSelected
              ? 'assets/icons/알림it_중요공지_O.svg'
              : 'assets/icons/알림it_중요공지_X.svg',
        ),
      ),
    );
  }
  Widget _bookmarkInfoButton() {
    bool isSelected = selectedIndex == 2;

    return SizedBox(
      height: 26.64,
      width: 60.6,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = 2;
            printBookmarks();
          });
        },
        child: SvgPicture.asset(
          isSelected
              ? 'assets/icons/알림it_북마_O.svg'
              : 'assets/icons/알림it_북마_X.svg',
        ),
      ),
    );
  }

  Widget _buildButton(int index, String text, double width) {
    bool isSelected = selectedIndex == index;
    return SizedBox(
      height: 26.64,
      width: width,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedIndex = index; // 선택된 버튼의 index 변경
            if(index==2){printBookmarks();};
          });
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: isSelected ? Color(0xff009D72) : Color(0xffEEEEEE),
        ),
        child: Center(
          child: Padding(padding: EdgeInsets.only(top: 2  ), child: Text(
            text,
            style: TextStyle(
              fontSize: 15.12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Color(0xffFFFFFF) : Color(0xff666666),
            ),
          ),)
        ),
      ),
    );
  } //전체, 중요 공지, 북마크

  Widget _ITICTButton(int index, String text, String val) {
    bool isSelected = selectedBSIndex == index;
    return SizedBox(
      height: 55,
      width: 155,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBSIndex = index;
            _updateButtonText(val);
          });
        },
        child: Container(
            height: 55,
            width: 155,
            margin: EdgeInsets.only(top: 5),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: isSelected ? Colors.black : Colors.white)),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 17.69,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              child: Text(
                text,
              ),
            )),
      ),
    );
  } // 하단 시트 버튼

  Widget _ITAIButton(int index, String text, String val) {
    bool isSelected = selectedBSIndex2 == index;
    return SizedBox(
      height: 55,
      width: 155,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBSIndex2 = index;
            _updateButtonText(val);
          });
        },
        child: Container(
            height: 55,
            width: 155,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            margin: EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: isSelected ? Colors.black : Colors.white)),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 17.69,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              child: Text(
                text,
              ),
            )),
      ),
    );
  } // 하단 시트 버튼

  Future<List<ElementWidget>> getFilteredElements() async {
    List<String> bookmarkedItems = await bookmarkManager.getBookmarks();

    return elements.where((element) {
      bool isBookmarked = bookmarkedItems.contains('${element.date}|${element.topic}');

      if (selectedIndex == 1 && !element.important) return false;
      if (selectedIndex == 2 && !isBookmarked) return false;

      return element.topic.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            padding: EdgeInsets.fromLTRB(30, 50, 30, 0),
            child: Column(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/알림it_uou.svg',
                          width: 32,
                          height: 16.33,
                        ),
                        Spacer(),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400), // 애니메이션 지속 시간
                          width: isTextFieldVisible ? 200 : 0, // 입력창 너비 조절
                          curve: Curves.easeInOut, // 부드러운 애니메이션 효과
                          child: isTextFieldVisible
                              ? SizedBox(
                                  height: 29,
                                  child: TextField(
                                    controller: _controller,
                                    style: TextStyle(
                                        fontSize: 15.12,
                                        fontWeight: FontWeight.bold),
                                    onChanged: (val) {
                                      setState(() {
                                        searchQuery = val; // 🔹 검색어 업데이트
                                      });
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xffDEDEDE)),
                                          borderRadius:
                                              BorderRadius.circular(67)),
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 15),
                                      filled: true,
                                      fillColor: Color(0xffDEDEDE),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xffDEDEDE)),
                                          borderRadius:
                                              BorderRadius.circular(67)),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xffDEDEDE)),
                                          borderRadius:
                                              BorderRadius.circular(67)),
                                    ),
                                  ),
                                )
                              : SizedBox(), // 입력창이 없을 때 빈 공간 처리
                        ),
                        if (!isTextFieldVisible) _bellIcon(),
                        if (isTextFieldVisible)
                          IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  isTextFieldVisible = !isTextFieldVisible;
                                  searchQuery = '';
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                size: 20,
                              ))
                        else
                          IconButton(
                            onPressed: () {
                              setState(() {
                                isTextFieldVisible = !isTextFieldVisible;
                              });
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/알림it_검색.svg',
                            ),
                            iconSize: 160,
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        _allInfoButton(),
                        SizedBox(
                          width: 8,
                        ),
                        _importantInfoButton(),
                        SizedBox(
                          width: 8,
                        ),
                        _bookmarkInfoButton(),
                        Spacer(),
                        SizedBox(
                          height: 26.64,
                          width: 46.6,
                          child: GestureDetector(
                            onTap: _toggleBottomSheet,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(64.8),
                                  color: Color(0xffEEEEEE)),
                              child: Center(
                                  child: Text(
                                buttonText,
                                style: TextStyle(
                                    color: Color(0xff009D72),
                                    fontWeight: FontWeight.bold),
                              )),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 23,
                    ),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.black,
                    )
                  ],
                ), //헤더
                Expanded(
                  child: FutureBuilder<List<ElementWidget>>(
                    future: getFilteredElements(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator()); // 로딩 표시
                      }

                      final filteredList = snapshot.data!;

                      if (filteredList.isEmpty) {
                        return Center(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 110), // 원하는 만큼 위쪽 여백 조정
                            child: SvgPicture.asset(
                              'assets/icons/알림it_UOU_big.svg',
                              width: 80.52,
                              height: 110.74,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return filteredList[index];
                        },
                        padding: EdgeInsets.zero,
                      );
                    },
                  )
                ) //바디
              ],
            ),
          ),
        ),
        if (_isBottomSheetVisible)
          DraggableScrollableSheet(
            initialChildSize: 0.35, // 초기 높이
            minChildSize: 0.1, // 최소 높이
            maxChildSize: 0.35, // 최대 높이
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                    color: Color(0xffEFEFF1),
                    borderRadius: BorderRadius.circular(30.0)),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.delta.dy > 0) {
                          _toggleBottomSheet(); // 드래그 시 아래로 내리면 사라지게 함
                        }
                      },
                      child: Center(
                        child: Container(
                          height: 5,
                          width: 60,
                          decoration: BoxDecoration(
                              color: Color(0xffD7D7D7),
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ITICTButton(0, 'ICT 융합학부', 'ICT'),
                                SizedBox(
                                  width: 5,
                                ),
                                Column(
                                  children: [
                                    _ITICTButton(1, 'IT 융합학부', 'IT'),
                                    if (selectedBSIndex == 1)
                                      Column(
                                        children: [
                                          _ITAIButton(0, 'IT 융합전공', 'IT'),
                                          _ITAIButton(1, 'AI 융합전공', 'AI')
                                        ],
                                      )
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

