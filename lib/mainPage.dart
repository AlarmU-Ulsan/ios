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
import 'keys.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class MainPage extends StatefulWidget {
  MainPage({
    super.key,
    List<String>? selectedAlram,
    this.selectedMajor = 'IT융합전공',
    this.changeMajor = false,
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
  // 북마크
  BookmarkManager bookmarkManager = BookmarkManager();

  int pageNum = 0;
  String type = '전체';

  // ✅ late 제거 + 기본값 세팅 (앱 재시작 시 초기화 꼬임/late 크래시 방지)
  String selectedMajor = 'IT융합전공';

  // ✅ prefs(alarm_majors) 값을 state로 들고 있게 (FCM 구독/벨 상태 일관성)
  List<String> selectedAlarmMajors = [];

  List<ElementWidget> elements = [];

  // 개인정보
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
                          child: const Text('닫기',
                              style: TextStyle(color: Colors.black)),
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

  // 알림
  bool selected_bell = false; // bell 상태는 prefs 기반으로 세팅
  Widget _bellIcon() {
    return GestureDetector(
      onLongPress: () => showPushDebugDialog(context),
      onTap: () async {
        String deviceID = await getDeviceId();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AlarmPage(deviceId: deviceID)),
        );
      },
      child: selected_bell
          ? SvgPicture.asset('assets/icons/알림it_bell.svg')
          : SvgPicture.asset('assets/icons/알림it_bell_f.svg'),
    );
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  ///
  ///
  String? _debugApnsToken;
  String? _debugFcmToken;
  AuthorizationStatus? _debugAuthStatus;
  String _debugStatusLog = "";
  ///
  ///

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    _debugStatusLog = "Firebase init OK\n";

    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _debugAuthStatus = settings.authorizationStatus;
      _debugStatusLog += "iOS 권한: ${settings.authorizationStatus}\n";
    }

    // ✅ FCM
    _debugFcmToken = await _messaging.getToken();
    if (_debugFcmToken != null) {
      _debugStatusLog += "FCM token OK\n";
      await _fcmPost();
    } else {
      _debugStatusLog += "❌ FCM token NULL\n";
    }

    // ✅ APNs
    for (int i = 0; i < 5; i++) {
      _debugApnsToken = await _messaging.getAPNSToken();
      if (_debugApnsToken != null) break;
      await Future.delayed(const Duration(seconds: 2));
    }

    if (_debugApnsToken != null) {
      _debugStatusLog += "APNs token OK\n";
    } else {
      _debugStatusLog += "❌ APNs token NULL\n";
    }
  }

  ///
  ///
  Future<void> showPushDebugDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🔔 Push Debug Status"),
        content: SingleChildScrollView(
          child: SelectableText(
            '''
[권한]
${_debugAuthStatus ?? "unknown"}

[FCM Token]
${_debugFcmToken != null ? "OK" : "NULL"}

[APNs Token]
${_debugApnsToken != null ? "OK" : "NULL"}

[Raw Log]
$_debugStatusLog
          ''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }
  ///
  ///

  void setupMessageListener() {
    print('setupmessageListener 함수 정상 적용');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('✅ 수신 성공');
      print('🔹 message: ${message.toMap()}');

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
        payload: message.data['link'],
      );
    });

    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          print("🔔 알림 클릭 시 payload: $payload");
        }
      },
    );

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final link = message.data['link'];
        print("앱 종료 상태에서 알림 클릭, 링크: $link");
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
  }

  String? fcmToken;

  Future<void> _fcmPost() async {
    print('\n===== 기기등록 API =====');
    if (fcmToken == null) {
      print("⚠️ FCM 토큰이 존재하지 않습니다.");
      return;
    }

    String deviceId = await getDeviceId();
    final ApiService apiService = ApiService(url: "$port/fcm/fcm_token");

    try {
      final response = await apiService.postFCMToken(deviceId, fcmToken!);
      final message = response['message'] ?? '응답 메시지가 없습니다.';
      print("📨 서버 응답: $message");
    } catch (e, st) {
      print("❌ _fcmPost error: $e");
      print(st);
      showNotification("서버 요청 중 오류가 발생했습니다.");
    }
  }

  Future<void> _subscribeMajor() async {
    print('\n===== 전공구독 API =====');

    // ✅ prefs 기반 리스트로 구독
    final List<String> majors = selectedAlarmMajors;
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

    if (!mounted) return;
    if (allSuccess) {
      setState(() {
        selected_bell = true;
      });
    } else {
      showNotification("일부 전공 구독에 실패했습니다.");
    }
  }

  Future<void> showNotification(String text) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      '일반 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '알림 설정',
      text,
      notificationDetails,
    );
  }

  // 검색
  bool isTextFieldVisible = true;
  final TextEditingController _controller = TextEditingController();
  String searchQuery = '';

  void _onSearchChanged(String query) {
    if (query.length < 2) return;
    _fetchSearchResults(query);
  }

  Future<void> _fetchSearchResults(String keyword) async {
    if (isLoading || !mounted) return;
    setState(() => isLoading = true);

    try {
      final ApiService apiServiceSearch = ApiService(
        url: "$port/search?keyWord=$keyword&major=$selectedMajor&page=0",
      );

      final notices = await apiServiceSearch.fetchNotices();

      for (final n in notices) {
        _noticeCache[n.id] = n;
      }

      if (!mounted) return;
      final fetchedElements = notices.map((notice) {
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
        elements = fetchedElements;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print('데이터 로드 실패: $e');
    }
  }

  // 필터
  int selectedIndex = 0;
  bool isLoading = false;
  int _missingBookmarksInCache = 0;

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
          });
          loadData();
        },
        child: SvgPicture.asset(
          isSelected ? 'assets/icons/알림it_전체_O.svg' : 'assets/icons/알림it_전체_X.svg',
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
          });
          loadData();
        },
        child: SvgPicture.asset(
          isSelected ? 'assets/icons/알림it_중요공지_O.svg' : 'assets/icons/알림it_중요공지_X.svg',
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
          isSelected ? 'assets/icons/알림it_북마_O.svg' : 'assets/icons/알림it_북마_X.svg',
        ),
      ),
    );
  }

  Future<void> updateElements() async {
    final bookmarkedItems = await bookmarkManager.getBookmarks();
    final notices = await loadBookmarkedItemsFromCache(bookmarkedItems);

    if (!mounted) return;
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
        elements = fetchedElements;
      }
    });
  }

  Future<List<Notice>> loadBookmarkedItems(List<String> bookmarkedItems) async {
    final apiService = ApiService(
      url: "$port/notice?type=전체&page=$pageNum&major=$selectedMajor",
    );

    final allNotices = await apiService.fetchNotices();
    return allNotices.where((notice) => bookmarkedItems.contains('${notice.id}')).toList();
  }

  Future<List<Notice>> loadBookmarkedItemsFromCache(List<String> bookmarkedItems) async {
    final ids = bookmarkedItems.map((e) => int.tryParse(e)).whereType<int>().toList();

    final List<Notice> result = [];
    int missingCount = 0;

    for (final id in ids) {
      final hit = _noticeCache[id];
      if (hit != null) {
        result.add(hit);
      } else {
        missingCount++;
      }
    }

    _missingBookmarksInCache = missingCount;
    return result;
  }

  final Map<int, Notice> _noticeCache = {};

  Future<void> loadData() async {
    if (isLoading || !mounted) return;

    setState(() => isLoading = true);

    try {
      final ApiService apiServiceAll = ApiService(
        url: "$port/notice?type=전체&page=0&major=$selectedMajor",
      );
      final ApiService apiServiceImportant = ApiService(
        url: "$port/notice?type=공지&page=0&major=$selectedMajor",
      );

      final bookmarkedItems = await bookmarkManager.getBookmarks();
      List<Notice> notices;

      if (selectedIndex == 0) {
        notices = await apiServiceAll.fetchNotices();
      } else if (selectedIndex == 1) {
        notices = await apiServiceImportant.fetchNotices();
      } else if (selectedIndex == 2) {
        notices = await loadBookmarkedItems(bookmarkedItems);
      } else {
        notices = [];
      }

      for (final n in notices) {
        _noticeCache[n.id] = n;
      }

      if (!mounted) return;
      final fetchedElements = notices.map((notice) {
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
        elements = fetchedElements;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print("데이터 로드 실패: $e");
    }
  }

  Future<void> loadNewData() async {
    if (isLoading || !mounted) return;

    setState(() {
      isLoading = true;
      if (selectedIndex == 0) pageNum++;
    });

    try {
      final ApiService apiServiceAll = ApiService(
        url: "$port/notice?type=전체&page=$pageNum&major=$selectedMajor",
      );
      final ApiService apiServiceImportant = ApiService(
        url: "$port/notice?type=중요 공지&page=$pageNum&major=$selectedMajor",
      );

      final bookmarkedItems = await bookmarkManager.getBookmarks();
      List<Notice> notices;

      if (selectedIndex == 0) {
        notices = await apiServiceAll.fetchNotices();
      } else if (selectedIndex == 1) {
        notices = await apiServiceImportant.fetchNotices();
      } else if (selectedIndex == 2) {
        notices = await loadBookmarkedItems(bookmarkedItems);
      } else {
        notices = [];
      }

      for (final n in notices) {
        _noticeCache[n.id] = n;
      }

      if (!mounted) return;
      final existingIds = elements.map((e) => e.id).toSet();
      final fetchedElements = notices
          .where((notice) => !existingIds.contains(notice.id))
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
        elements.addAll(fetchedElements);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print("데이터 로드 실패: $e");
    }
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading) {
        final currentScrollPosition = _scrollController.position.pixels;
        await loadNewData();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(currentScrollPosition - 5);
          }
        });
      }
    }
  }

  void _navigateAndGetMajor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPage(selectedMajor: selectedMajor),
      ),
    );

    if (!mounted || result == null) return;

    // CategoryPage에서 Map으로 내려주는 경우
    if (result is Map) {
      final newMajor = result["selectedMajor"] as String?;
      final changed = result["changed"] as bool? ?? false;

      if (newMajor != null && newMajor.isNotEmpty) {
        setState(() {
          selectedMajor = newMajor;
          // (선택) 변경 여부 상태로 쓰고 싶으면 여기서 저장
          // widget.changeMajor 대신 state 변수로 snackbar 제어 가능
        });

        loadData();

        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        // (선택) changed면 스낵바 띄우기
        if (changed) {
          // snackbar 띄우는 기존 로직을 여기로 옮겨도 됨
        }
      }
      return;
    }

    // 혹시 예전처럼 String만 내려주는 경우도 안전하게 처리
    if (result is String && result.isNotEmpty) {
      setState(() {
        selectedMajor = result;
      });
      loadData();
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ Init 페이지 저장값 로드 + bell 초기값 + 알림 리스트 로드(구독 기준)
  Future<void> _loadPrefsAndApply() async {
    final prefs = await SharedPreferences.getInstance();

    final mainMajor = prefs.getString(kMainMajorKey);
    final alarmMajors = prefs.getStringList(kAlarmMajorsKey) ?? [];

    // 대표 전공 결정 (prefs 우선)
    final resolvedMainMajor =
    (mainMajor != null && mainMajor.isNotEmpty) ? mainMajor : widget.selectedMajor;

    // 알림 전공 리스트 결정
    // - prefs에 있으면 그것
    // - 없으면 대표전공 1개로 기본
    final resolvedAlarmMajors =
    alarmMajors.isNotEmpty ? alarmMajors : [resolvedMainMajor];

    if (!mounted) return;
    setState(() {
      selectedMajor = resolvedMainMajor;
      selectedAlarmMajors = resolvedAlarmMajors;
      selected_bell = alarmMajors.isNotEmpty; // ✅ bell은 "prefs에 진짜로 알림전공이 저장돼있냐"로만 판단
    });
  }

  Future<void> _checkConsentAndInitFCM() async {
    final prefs = await SharedPreferences.getInstance();
    final consented = prefs.getBool("privacy_consent_v1") ?? false;

    if (consented) {
      await _initializeFirebase();
      setupMessageListener();
      print("✅ 개인정보 동의함 → FCM 구독 진행");
    } else {
      print("❌ 개인정보 동의 안 함 → FCM 구독 막음");
    }
  }

  // ✅ initState에서 "prefs 로드 후 loadData" 하도록 순서 정리
  @override
  void initState() {
    super.initState();

    // 기본값 먼저 세팅 (build 안정성)
    selectedMajor = widget.selectedMajor;
    selectedAlarmMajors = widget.selectedAlram;
    selected_bell = false;

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPrefsAndApply();   // ✅ 여기서 selectedMajor/bell/알림리스트 확정
    await loadData();             // ✅ 이제 올바른 selectedMajor로 첫 로드
    _scrollController.addListener(_scrollListener);
    await _checkConsentAndInitFCM();

    if (widget.changeMajor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '전공이 변경되었어요!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    '공지 채널을 변경해도 새 공지의\n알림을 받는 채널은 변경되지 않아요!',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  )
                ],
              ),
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xff009D72),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(60),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _controller.dispose();
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
                    SizedBox(height: 20),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/알림it_icon.svg',
                          width: 21,
                          height: 22,
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            _navigateAndGetMajor();
                          },
                          child: Row(
                            children: [
                              Text(selectedMajor),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                                size: 15,
                              )
                            ],
                          ),
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
                              });
                              loadData();
                            },
                            icon: Icon(Icons.close, size: 20),
                          )
                        else
                          IconButton(
                            onPressed: () {
                              setState(() {
                                isTextFieldVisible = !isTextFieldVisible;
                              });
                            },
                            icon: SvgPicture.asset('assets/icons/알림it_검색.svg'),
                            iconSize: 160,
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (isTextFieldVisible)
                      Row(
                        children: [
                          _allInfoButton(),
                          SizedBox(width: 8),
                          _importantInfoButton(),
                          SizedBox(width: 8),
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      searchQuery = val;
                                      _onSearchChanged(val);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: "검색어를 입력해주세요",
                                    hintStyle:
                                    TextStyle(color: Color(0xffA3A3A3)),
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(bottom: 5),
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(0, 0, 15, 5),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Text('검색',
                                      style: TextStyle(color: Color(0xff009D72))),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 2, color: Color(0xff009D72)),
                        ],
                      ),
                    SizedBox(height: 23),
                    if (isTextFieldVisible)
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.black,
                      )
                  ],
                ),
                if (isLoading) Center(child: null),
                if (!isLoading && elements.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      controller: _scrollController,
                      itemCount: elements.length,
                      itemBuilder: (context, index) {
                        return elements[index];
                      },
                    ),
                  ),
                if (!isLoading && elements.isEmpty)
                  Column(
                    children: [
                      SizedBox(height: 230),
                      Text(
                        '공지된 북마크가 없습니다',
                        style: TextStyle(fontSize: 20, color: Color(0xff9C9C9C)),
                      ),
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