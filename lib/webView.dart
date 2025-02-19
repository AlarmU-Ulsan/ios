import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController controller;

  void _launchURL() async {
    if (await canLaunch(widget.url)) {
      await launch(widget.url);  // URL을 사파리에서 열기
    } else {
      throw 'Could not launch $widget.url';
    }
  }

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // 자바스크립트 허용
      ..loadRequest(Uri.parse(widget.url)); // URL 로드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
          WebViewWidget(controller: controller),
          Positioned(
          bottom: 700, // 아래에서 50 픽셀 위치
          right: 320, // 오른쪽에서 20 픽셀 위치
          child: SizedBox(
            height: 62,
            width: 59,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset('assets/icons/알림it_back.svg'),
            ),
          ),
        ),]),
        floatingActionButton: GestureDetector(
          onTap: () {
            _launchURL();
          },
          child: Container(
            width: 115, // 원하는 버튼 크기
            height: 42, // 원하는 버튼 크기
            decoration: BoxDecoration(
              shape: BoxShape.circle, // 원형 버튼
              color: Colors.transparent, // 버튼 배경색
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/알림it_웹버튼.svg', // SVG 파일 경로
                width: 40, // 이미지 크기
                height: 40, // 이미지 크기
              ),
            ),
          ),
        ));
  }
}
