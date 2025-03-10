import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:notification_it/majorCategory.dart';
import 'package:notification_it/splashScreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'list_elements.dart';
import 'api_service.dart';

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
  static _MainPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainPageState>();
  }
}

class _MainPageState extends State<MainPage> {
  //북마크
  BookmarkManager bookmarkManager = BookmarkManager(); //북마크 관리

  int pageNum = 0;
  int categoryNum = 2;
  List<ElementWidget> elements = [];
  Future<void> fetchInitialData() async {
    List<ElementWidget> result = await getFilteredElements(); // 비동기 데이터 로드
    setState(() {
      elements = result;
    });
  } //데이터 불러오기

  Future<List<ElementWidget>> getFilteredElements() async {
    final ApiService apiService = ApiService(
        url:
            "https://alarm-it.ulsan.ac.kr:58080/notice?category=$categoryNum&page=$pageNum"); // API URL 입력
    List<String> bookmarkedItems = await bookmarkManager.getBookmarks();

    try {
      List<Notice> notices = await apiService.fetchNotices();

      // Notice 데이터를 ElementWidget 리스트로 변환
      List<ElementWidget> elements = notices.map((notice) {
        return ElementWidget(
          id: notice.id,
          title: notice.title,
          date: notice.date,
          link: notice.link,
          type: notice.type, // 필요 시 수정
          major: notice.major,
        );
      }).toList();

      // 필터링 적용
      return elements.where((element) {
        bool isBookmarked =
            bookmarkedItems.contains('${element.date}|${element.title}');

        if (selectedIndex == 1 && element.type != "NOTICE")
          return false; // "중요" 공지만 보기
        if (selectedIndex == 2 && !isBookmarked) return false; // 북마크된 항목만 보기

        return element.title.contains(searchQuery); // 검색 필터 적용
      }).toList();
    } catch (e) {
      print("데이터 로드 실패: $e");
      return []; // 오류 발생 시 빈 리스트 반환
    }
  } //필터링 후 위젯으로 변환

  //스크롤에 대한 동작
  bool isLoading = false; // 데이터를 로딩 중인지 확인하는 변수

  //푸시알림
  Widget _bellIcon() {
    bool isSelected_bell = selected_bell;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (!selected_bell)
            showNotification('알림이 설정되었습니다');
          else
            showNotification('알림이 해제되었습니다');
          selected_bell = !selected_bell;
        });
      },
      child: isSelected_bell
          ? SvgPicture.asset(
              'assets/icons/알림it_bell_O.svg',
            )
          : SvgPicture.asset(
              'assets/icons/알림it_bell_X.svg',
            ),
    );
  }

  bool selected_bell = false; //알림 on/off
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
  } //알림

  //검색창
  bool isTextFieldVisible = false;
  TextEditingController _controller = TextEditingController();
  String searchQuery = ''; //검색어 저장 변수

  //필터 버튼
  Widget _allInfoButton() {
    bool isSelected = selectedIndex == 0;

    return SizedBox(
      height: 26.64,
      width: 47.6,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = 0;
            loadData();
            print('all');
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
            loadData();
            print('important');
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
            loadData();
            print('bookmark');
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

  //필터 값
  int selectedIndex = 0; // 0: 전체, 1: 중요 공지, 2: 북마크
  int selectedBSIndex = 0; // 0: ICT, 1: IT
  int selectedBSIndex2 = 0; // 0: IT, 1: AI

  //새로 시작
  Future<void> updateElements() async {
    List<String> bookmarkedItems = await bookmarkManager.getBookmarks();
    // 북마크된 항목을 새로 불러오기
    List<Notice> notices = await loadBookmarkedItems(bookmarkedItems);

    // 새로 불러온 데이터를 화면에 표시하기 위해 ElementWidget으로 변환
    List<ElementWidget> fetchedElements = notices.map((notice) {
      return ElementWidget(
        id: notice.id,
        title: notice.title,
        date: notice.date,
        link: notice.link,
        type: notice.type,
        major: notice.major,
      );
    }).toList();

    setState(() {
      if (selectedIndex == 2) {
        elements = fetchedElements; // 새로 불러온 데이터로 업데이트
      }
    });
  }

  Future<List<Notice>> loadBookmarkedItems(List<String> bookmarkedItems) async {
    final apiService = ApiService(
        url:
            "https://alarm-it.ulsan.ac.kr:58080/notice?category=$categoryNum&page=$pageNum");

    List<Notice> allNotices = await apiService.fetchNotices(); // 전체 데이터를 불러옴

    return allNotices.where((notice) {
      // 북마크된 항목만 필터링
      return bookmarkedItems.contains('${notice.id}');
    }).toList();
  }

  Future<void> loadData() async {
    try {
      final ApiService apiServiceAll = ApiService(
          url:
              "https://alarm-it.ulsan.ac.kr:58080/notice?category=$categoryNum&page=0");
      final ApiService apiServiceImportant = ApiService(
          url:
              "https://alarm-it.ulsan.ac.kr:58080/notice?category=$categoryNum&page=0");
      List<String> bookmarkedItems = await bookmarkManager.getBookmarks();
      List<Notice> notices;

      if (selectedIndex == 0) {
        // 전체 데이터를 가져오는 경우, 새로 API 호출하지 않고 기존 elements 그대로 사용
        notices = await apiServiceAll.fetchNotices();
      } else if (selectedIndex == 1) {
        print(selectedIndex);
        // 중요 데이터를 가져오는 경우, 새로 API 호출 후 중요 필터링
        notices = await apiServiceImportant.fetchNotices();
        notices = notices
            .where((notice) => notice.type == "NOTICE")
            .toList(); // 중요 공지만 필터링
      } else if (selectedIndex == 2) {
        // 북마크된 데이터를 가져오는 경우
        notices = await loadBookmarkedItems(bookmarkedItems);
        // selectedIndex == 2;
      } else {
        notices = [];
      }

      // Notice 데이터를 ElementWidget 리스트로 변환
      List<ElementWidget> fetchedElements = notices.map((notice) {
        return ElementWidget(
          id: notice.id,
          title: notice.title,
          date: notice.date,
          link: notice.link,
          type: notice.type,
          major: notice.major,
        );
      }).toList();

      setState(() {
        elements = fetchedElements; // 새로운 데이터를 elements에 할당
        isLoading = false; // 로딩 완료
      });
    } catch (e) {
      setState(() {
        isLoading = false; // 오류 발생 시 로딩 종료
      });
      print("데이터 로드 실패: $e");
    }
  }

  Future<void> loadNewData() async {
    setState(() {
      pageNum++;
    });
    try {
      final ApiService apiServiceAll = ApiService(
          url:
              "https://alarm-it.ulsan.ac.kr:58080/notice?category=$categoryNum&page=$pageNum");
      final ApiService apiServiceImportant = ApiService(
          url:
              "https://alarm-it.ulsan.ac.kr:58080/notice?category=$categoryNum&page=$pageNum");
      List<String> bookmarkedItems = await bookmarkManager.getBookmarks();
      List<Notice> notices;

      if (selectedIndex == 0) {
        // 전체 데이터를 가져오는 경우, 새로 API 호출하지 않고 기존 elements 그대로 사용
        notices = await apiServiceAll.fetchNotices();
      } else if (selectedIndex == 1) {
        print(selectedIndex);
        // 중요 데이터를 가져오는 경우, 새로 API 호출 후 중요 필터링
        notices = await apiServiceImportant.fetchNotices();
        notices = notices
            .where((notice) => notice.type == "NOTICE")
            .toList(); // 중요 공지만 필터링
      } else if (selectedIndex == 2) {
        // 북마크된 데이터를 가져오는 경우
        notices = await loadBookmarkedItems(bookmarkedItems);
        // selectedIndex == 2;
      } else {
        notices = [];
      }

      // Notice 데이터를 ElementWidget 리스트로 변환
      List<ElementWidget> fetchedElements = notices.map((notice) {
        return ElementWidget(
          id: notice.id,
          title: notice.title,
          date: notice.date,
          link: notice.link,
          type: notice.type,
          major: notice.major,
        );
      }).toList();

      setState(() {
        elements.addAll(fetchedElements); // 새로운 데이터를 elements에 할당
        isLoading = false; // 로딩 완료
      });
    } catch (e) {
      setState(() {
        isLoading = false; // 오류 발생 시 로딩 종료
      });
      print("데이터 로드 실패: $e");
    }
  }

  ScrollController _scrollController = ScrollController();
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // 스크롤 끝에 도달하면 추가 데이터를 로드
      loadNewData(); // 필요한 filterType을 넣어 호출
    }
  }

  final String category = 'ICT융합학부';

  @override
  void initState() {
    super.initState();
    fetchInitialData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
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
                        SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CategoryPage()));
                          },
                          child: Container(
                              child: Row(
                            children: [
                              Text(category),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                                size: 15,
                              )
                            ],
                          )),
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
                            ),
                          )
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
                ), // 헤더
                if (isLoading)
                  Center(child: CircularProgressIndicator()), // 로딩 상태일 때

                // 리스트 뷰 표시
                if (!isLoading && elements.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      controller: _scrollController,
                      itemCount: elements.length,
                      itemBuilder: (context, index) {
                        return elements[index]; // ElementWidget 반환
                      },
                    ),
                  ),
                if (!isLoading && elements.isEmpty)
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                          top: 250, bottom: 110), // 원하는 만큼 위쪽 여백 조정
                      child: SvgPicture.asset(
                        'assets/icons/알림it_UOU_big.svg',
                        width: 80.52,
                        height: 110.74,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
