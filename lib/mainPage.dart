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

import 'intro.dart';
import 'splashScreen.dart';
import 'init_selecet_page.dart';
import 'list_elements.dart';
import 'api_service.dart';
import 'intro.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

String port = 'https://alarm-it.ulsan.ac.kr/test';
// String port = 'https://alarm-it.ulsan.ac.kr';

class MainPage extends StatefulWidget {
  MainPage({
    super.key,
    List<String>? selectedAlram,
    this.selectedMajor = 'IT융합전공',
    this.changeMajor = false
  }) : selectedAlram = selectedAlram ?? ['IT융합전공'];

  final List<String> selectedAlram;
  final String selectedMajor;
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
  List<ElementWidget> elements = [];

  //개인정보
  Future<bool?> showPrivacyConsentBottomSheet(BuildContext context) {
    bool checked = true;

    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign, size: 40, color: Color(0xff009D72)),
                  const SizedBox(height: 8),
                  const Text(
                    '알림U 이용을 위해 동의가 필요해요',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: checked,
                        onChanged: (v) => setState(() => checked = v ?? false),
                      ),
                      const Text('개인정보 처리 동의'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // TODO: 상세보기 링크/화면
                        },
                        child: const Text('[자세히보기]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffE9E9E9),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('닫기', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff009D72),
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

  //알림
  Widget _bellIcon() {
    bool isSelected_bell = selected_bell;
    return GestureDetector(
      onTap: () async {
        String deviceID = await getDeviceId();
        Navigator.push(context, MaterialPageRoute(builder: (context)=>AlarmPage(deviceId: deviceID,)));
      },
      child: (isSelected_bell)
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
    if (apnsToken != null){
      print("🔹 APNS Token is available");}

    // APNS 토큰이 null이면 알림을 사용할 수 없음
    if (apnsToken == null) {
      print("⚠️ APNS 토큰을 가져올 수 없습니다.");
      return;
    }

    // FCM 토큰 받기
    fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      print("🔹 FCM Token is available");}

    // FCM API 등록하기
    await _fcmPost();

    // 전공 구독하기
    if(widget.selectedMajor != null){
      await _subscribeMajor();
    }else{print('구독한 전공이 없습니다!!');}
  }
  void setupMessageListener() {
    print('setupmessageListener 함수 정상 적용');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('✅ 수신 성공');
      print('🔹 message: ${message.toMap()}');
      print('🔸 title: ${message.notification?.title}');
      print('🔸 body: ${message.notification?.body}');
      print('🔸 data: ${message.data}');

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
        payload: message.data['link'],  // 알림 클릭 시 전달할 데이터 (예: 링크)
      );
    });

    // 알림 클릭 시 처리 (앱이 백그라운드 또는 종료 상태에서)
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          // TODO: payload를 이용해 링크 열기, 화면 이동 등 처리
          print("🔔 알림 클릭 시 payload: $payload");
        }
      },
    );

    // 앱이 완전히 종료된 상태에서 알림 클릭 시 getInitialMessage 확인도 필요
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final link = message.data['link'];
        print("앱 종료 상태에서 알림 클릭, 링크: $link");
        // TODO: 링크를 이용해 화면 이동 처리
      }
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
    print('\n===== 기기등록 API =====');
    if (fcmToken == null) {
      print("⚠️ FCM 토큰이 존재하지 않습니다.");
      return;
    }
    String deviceId = await getDeviceId();

    final ApiService apiService = ApiService(url: "$port/fcm/fcm_token");

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
    print('\n===== 전공구독 API =====');
    final List<String> majors = widget.selectedAlram;
    print('구독요청 전공: $majors');
    String deviceId = await getDeviceId();
    final ApiService apiService = ApiService(url: "$port/fcm/subscribe");

    bool allSuccess = true;

    for (String major in majors) {
      try {
        final response = await apiService.subscribeNotice(deviceId, major);
        final message = response['message'] ?? '응답 메시지가 없습니다.';
        print("✅ [$major] 구독 성공: $message");
      } catch (e) {
        allSuccess = false;
        print("❌ [$major] 구독 실패: $e");
      }
    }


    // ✅ UI 상태 업데이트 (모든 구독 성공 시만 알림 아이콘 상태 변경)
    if (!mounted) return;
    if (allSuccess) {
      setState(() {
        selected_bell = true;
      });
    } else {
      showNotification("일부 전공 구독에 실패했습니다.");
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
      "$port/search?keyWord=$keyword&major=$selectedMajor&page=0");
      List<Notice> notices;

      notices = await apiServiceSearch.fetchNotices();

      for (final n in notices) {
        _noticeCache[n.id] = n;
      }

      if (!mounted) return;
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
      if (!mounted) return;
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
        onTap: () async {
          setState(() {
            selectedIndex = 2;
            pageNum = 0;
            elements = [];
          });

          await updateElements();
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

  bool isLoading = false; // 데이터를 로딩 중인지 확인하는 변수

  int _missingBookmarksInCache = 0;

  Future<void> updateElements() async {
    final bookmarkedItems = await bookmarkManager.getBookmarks();
    final notices = await loadBookmarkedItemsFromCache(bookmarkedItems);

    if (!mounted) return;
    // 새로 불러온 데이터를 화면에 표시하기 위해 ElementWidget으로 변환
    final fetchedElements = notices.map((n) => ElementWidget(
      id: n.id,
      title: n.title,
      date: n.date,
      link: n.link,
      type: n.type,
      major: n.major,
    )).toList();

    setState(() {
      if (selectedIndex == 2) {
        elements = fetchedElements; // 새로 불러온 데이터로 업데이트
      }
    });
  }

  Future<List<Notice>> loadBookmarkedItems(List<String> bookmarkedItems) async {
    final apiService = ApiService(
        url:
        "$port/notice?type=전체&page=$pageNum&major=$selectedMajor");

    List<Notice> allNotices = await apiService.fetchNotices(); // 전체 데이터를 불러옴

    return allNotices.where((notice) {
      // 북마크된 항목만 필터링
      return bookmarkedItems.contains('${notice.id}');
    }).toList();
  }
  Future<List<Notice>> loadBookmarkedItemsFromCache(List<String> bookmarkedItems) async {
    // 저장 형태가 String이면 int로 변환
    final ids = bookmarkedItems.map((e) => int.tryParse(e)).whereType<int>().toList();

    // 순서 보존: 북마크에 저장된 순서대로 표시하고 싶을 때
    final List<Notice> result = [];
    int missingCount = 0;

    for (final id in ids) {
      final hit = _noticeCache[id];
      if (hit != null) {
        result.add(hit);
      } else {
        missingCount++; // 캐시에 아직 없는 항목
      }
    }

    // (선택) 상태 보이기 위해 멤버로 보관
    _missingBookmarksInCache = missingCount; // _MainPageState에 int 멤버 추가

    return result;
  }

  final Map<int, Notice> _noticeCache = {};
  Future<void> loadData() async {
    if (isLoading || !mounted) return;  // 이미 로딩 중이면 실행하지 않음

    setState(() {
      isLoading = true;
    });
    try {
      final ApiService apiServiceAll = ApiService(
          url:
          "$port/notice?type=전체&page=0&major=$selectedMajor");
      final ApiService apiServiceImportant = ApiService(
          url:
          "$port/notice?type=중요 공지&page=0&major=$selectedMajor");
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
      for (final n in notices){
        _noticeCache[n.id] = n;
      }

      // Notice 데이터를 ElementWidget 리스트로 변환
      if (!mounted) return;
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
      if (!mounted) return;
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
          "$port/notice?type=전체&page=$pageNum&major=$selectedMajor");
      final ApiService apiServiceImportant = ApiService(
          url:
          "$port/notice?type=중요 공지&page=$pageNum&major=$selectedMajor");
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

      // loadNewData() 내부, notices 받은 직후
      for (final n in notices) {
        _noticeCache[n.id] = n;
      }

      if (!mounted) return;
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
      if (!mounted) return;
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
    _initializeFirebase().then((_){setupMessageListener();});
    selectedMajor = widget.selectedMajor;
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