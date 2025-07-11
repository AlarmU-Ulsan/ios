import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:notification_it/alram.dart';
import 'package:notification_it/majorCategory.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'list_elements.dart';
import 'api_service.dart';
import 'intro.dart';

String port = '6004';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
} //알림 권한 요청

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //로컬 푸시 알림 초기화

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); //firebase 초기화

  final DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await requestLocalNotificationPermissions(); //ios 권한 요청
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
  print('🔔 권한 상태: ${settings.authorizationStatus}');

  runApp(Notification_IT());
}

class Notification_IT extends StatelessWidget {
  const Notification_IT({super.key});

  Future<bool> checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('hasSeenIntro') ?? false;
    return !hasSeen;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '알림it',
      home: FutureBuilder<bool>(
        future: checkFirstSeen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox(); // 로딩 대기
          return snapshot.data! ? IntroPage() : MainPage();
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    this.selectedMajor = 'IT융합학부',
    this.selectedAlram = '',
    this.changeMajor = false
  });

  final String selectedMajor;
  final String selectedAlram;
  final bool changeMajor;

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
  String type = '전체';
  late String selectedMajor;
  late String selectedAlram;
  List<ElementWidget> elements = [];

  //알림
  Widget _bellIcon() {
    bool isSelected_bell = selected_bell;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>AlarmPage()));
      },
      child: (selectedAlram != '')
          ? SvgPicture.asset(
              'assets/icons/알림it_bell.svg',
            )
          : SvgPicture.asset(
              'assets/icons/알림it_bell.svg',
            ),
    );
  }
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Future<void> _initializeFirebase() async {
    // Firebase 초기화
    await Firebase.initializeApp();
    print("Firebase 초기화 완료");

    // iOS에서 권한 요청
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // APNS 토큰 가져오기 (iOS에서만)
    String? apnsToken = await _messaging.getAPNSToken();
    print("🔹 APNS Token: $apnsToken");

    // APNS 토큰이 null이면 알림을 사용할 수 없음
    if (apnsToken == null) {
      print("⚠️ APNS 토큰을 가져올 수 없습니다.");
      return;
    }

    // FCM 토큰 받기
    fcmToken = await _messaging.getToken();
    print("🔹 FCM Token: $fcmToken");

    // FCM API 등록하기
    await _fcmPost();

    // 전공 구독하기
    if(widget.selectedMajor != null){
      await _subscribeMajor();
    }else{print('구독한 전공이 없습니다!!');}

    // 포그라운드 알림 전송하기
    setupMessageListener();
  }
  void setupMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 포그라운드 메시지 수신: ${message.notification?.title} - ${message.notification?.body}");

      // 알림 표시
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? '제목 없음',
        message.notification?.body ?? '내용 없음',
        NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'channel_id',
            '일반 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios_id";
    } else {
      return "unsupported_platform";
    }
  } //디바이스 ID 가져오기
  Future<void> _fcmPost() async {
    if (fcmToken == null) {
      print("⚠️ FCM 토큰이 존재하지 않습니다.");
      return;
    }
    String deviceId = await getDeviceId();

    final ApiService apiService = ApiService(url: "https://alarm-it.ulsan.ac.kr:$port/fcm/fcm_token");

    try {
      // ✅ API 호출 및 응답 수신
      final response = await apiService.postFCMToken(deviceId, fcmToken!);
      final message = response['message'] ?? '응답 메시지가 없습니다.';
      print("📨 서버 응답: $message");

    } catch (e) {
      print("❌ 오류 발생: $e");
      showNotification("서버 요청 중 오류가 발생했습니다.");
    }
  } //fcm 등록
  Future<void> _subscribeMajor() async {
    final major = widget.selectedMajor;
    print('구독요청 전공: $major');
    String deviceId = await getDeviceId();

    final ApiService apiService = ApiService(url: "https://alarm-it.ulsan.ac.kr:$port/fcm/subscribe");

    try {
      // ✅ API 호출 및 응답 수신
      final response = await apiService.subscribeNotice(deviceId, major);
      final message = response['message'] ?? '응답 메시지가 없습니다.';
      print("📨 서버 응답: $message");

      // ✅ UI 상태 업데이트
      setState(() {
        selected_bell = true;
      });

    } catch (e) {
      print("❌ 오류 발생: $e");
      showNotification("서버 요청 중 오류가 발생했습니다.");
    }
  } //전공 구독
  bool selected_bell = false; //알림 on/off
  String? fcmToken;
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


  //검색창
  bool isTextFieldVisible = true;
  final TextEditingController _controller = TextEditingController();
  String searchQuery = ''; //검색어 저장 변수
  void _onSearchChanged(String query) {
    if (query.length < 2) return; // 너무 짧은 검색어는 요청하지 않음
    _fetchSearchResults(query);
  }
  Future<void> _fetchSearchResults(String keyword) async {
    if (isLoading || !mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final ApiService apiServiceSearch = ApiService(url:
      "https://alarm-it.ulsan.ac.kr:$port/search?keyWord=$keyword&major=$selectedMajor&page=0");
      List<Notice> notices;

      notices = await apiServiceSearch.fetchNotices();
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
      print('데이터 로드 실패: $e');
    }
  }

  //필터 버튼

  Widget _allInfoButton() {
    bool isSelected = selectedIndex == 0;

    return SizedBox(
      height: 26.64,
      width: 47.6,
      child: GestureDetector(
        onTap: () {
          setState(() {
            elements = [];
            selectedIndex = 0;
            pageNum = 0;
            type = '전체';
            loadData();
            print('all');
            print('pageNum = $pageNum');
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
            elements = [];
            pageNum = 0;
            type = '중요 공지';
            loadData();
            print('important');
            print('pageNum = $pageNum');
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
            pageNum = 0;
            elements = [];
            loadData();
            print('bookmark');
            print('pageNum = $pageNum');
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

  //새로 시작

  bool isLoading = false; // 데이터를 로딩 중인지 확인하는 변수

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
        "https://alarm-it.ulsan.ac.kr:$port/notice?type=전체&page=$pageNum&major=$selectedMajor");

    List<Notice> allNotices = await apiService.fetchNotices(); // 전체 데이터를 불러옴

    return allNotices.where((notice) {
      // 북마크된 항목만 필터링
      return bookmarkedItems.contains('${notice.id}');
    }).toList();
  }

  Future<void> loadData() async {
    if (isLoading || !mounted) return;  // 이미 로딩 중이면 실행하지 않음

    setState(() {
      isLoading = true;
    });
    try {
      final ApiService apiServiceAll = ApiService(
          url:
          "https://alarm-it.ulsan.ac.kr:$port/notice?type=전체&page=0&major=$selectedMajor");
      final ApiService apiServiceImportant = ApiService(
          url:
          "https://alarm-it.ulsan.ac.kr:$port/notice?type=중요 공지&page=0&major=$selectedMajor");
      List<String> bookmarkedItems = await bookmarkManager.getBookmarks();
      List<Notice> notices;

      if (selectedIndex == 0) {
        // 전체 데이터를 가져오는 경우, 새로 API 호출하지 않고 기존 elements 그대로 사용
        notices = await apiServiceAll.fetchNotices();
      } else if (selectedIndex == 1) {
        // 중요 데이터를 가져오는 경우, 새로 API 호출 후 중요 필터링
        notices = await apiServiceImportant.fetchNotices();
      } else if (selectedIndex == 2) {
        // 북마크된 데이터를 가져오는 경우
        notices = await loadBookmarkedItems(bookmarkedItems);
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
    if (isLoading || !mounted) return;  // 이미 로딩 중이면 실행하지 않음

    setState(() {
      isLoading = true;
      if(selectedIndex==0){
      pageNum++;}
    });

    try {
      // 현재 스크롤 위치 저장

      final ApiService apiServiceAll = ApiService(
          url:
          "https://alarm-it.ulsan.ac.kr:$port/notice?type=전체&page=$pageNum&major=$selectedMajor");
      final ApiService apiServiceImportant = ApiService(
          url:
          "https://alarm-it.ulsan.ac.kr:$port/notice?type=중요 공지&page=$pageNum&major=$selectedMajor");
      List<String> bookmarkedItems = await bookmarkManager.getBookmarks();
      List<Notice> notices;

      if (selectedIndex == 0) {
        // 전체 데이터를 가져오는 경우, 새로 API 호출하지 않고 기존 elements 그대로 사용
        notices = await apiServiceAll.fetchNotices();
      } else if (selectedIndex == 1) {
        // 중요 데이터를 가져오는 경우, 새로 API 호출 후 중요 필터링
        notices = await apiServiceImportant.fetchNotices();
      } else if (selectedIndex == 2) {
        // 북마크된 데이터를 가져오는 경우
        notices = await loadBookmarkedItems(bookmarkedItems);
      } else {
        notices = [];
      }

      Set<int> existingIds = elements.map((e) => e.id).toSet();
      // Notice 데이터를 ElementWidget 리스트로 변환
      List<ElementWidget> fetchedElements = notices
          .where((notice) => !existingIds.contains(notice.id)) // 중복 필터링
          .map((notice) => ElementWidget(
        id: notice.id,
        title: notice.title,
        date: notice.date,
        link: notice.link,
        type: notice.type,
        major: notice.major,
      ))
          .toList();


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



  final ScrollController _scrollController = ScrollController();
  void _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading) {
        double currentScrollPosition = _scrollController.position.pixels;

        await loadNewData();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(currentScrollPosition - 5);
          }
        });
      }
    }
  }

  //페이지 이동
  void _navigateAndGetMajor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryPage(selectedMajor: selectedMajor,)),
    );

    if (result != null) {
      setState(() {
        selectedMajor = result;
        loadData();//데이터 초기
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );//스크롤 최상단으로
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    selectedMajor = widget.selectedMajor;
    selectedAlram = widget.selectedAlram;
    if (widget.changeMajor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 15,vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전공이 변경되었어요!',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                  Text('공지 채널을 변경해도 새 공지의\n알림을 받는 채널은 변경되지 않아요!', style: TextStyle(fontSize: 11, color: Colors.white),)
                ],
              ),
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xff009D72),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(60),
            ),
              behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      });
    }
    loadData();
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
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/알림it_icon.svg',
                          width: 21,
                          height: 22,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {_navigateAndGetMajor();},
                          child: Container(
                              child: Row(
                                children: [
                                  Text(selectedMajor),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey,
                                    size: 15,
                                  )
                                ],
                              )),
                        ),
                        Spacer(),
                        _bellIcon(),
                        if (!isTextFieldVisible)
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                isTextFieldVisible = !isTextFieldVisible;
                                searchQuery = '';
                                loadData();
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
                      height: 20,
                    ),
                    if (isTextFieldVisible)
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
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  style: TextStyle(
                                      fontSize: 15.12,
                                      fontWeight: FontWeight.bold),
                                  onChanged: (val) {
                                    setState(() {
                                      searchQuery = val;// 🔹 검색어 업데이트
                                      _onSearchChanged(val);
                                    });
                                  },
                                  decoration: InputDecoration(
                                      hintText: "검색어를 입력해주세요",
                                      hintStyle: TextStyle(color: Color(0xffA3A3A3)),
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(bottom: 5),
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none
                                  ),
                                ),
                              ),
                              Container(
                                  padding:EdgeInsets.fromLTRB(0, 0, 15, 5),
                                  child: GestureDetector(
                                      onTap: (){},
                                      child: Text('검색', style: TextStyle(color: Color(0xff009D72)),)))
                            ],
                          ),
                          Container(height: 2, color: Color(0xff009D72),),
                        ],
                      ),
                    SizedBox(
                      height: 23,
                    ),
                    if(isTextFieldVisible)
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.black,
                      )
                  ],
                ), // 헤더
                if (isLoading)
                  Center(child: null,), // 로딩 상태일 때

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
                  Column(
                    children: [
                      SizedBox(height: 230,),
                      Text('공지된 북마크가 없습니다', style: TextStyle(fontSize:20, color: Color(0xff9C9C9C)),),
                    ],
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
