import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notification_it/init_selecet_page.dart';

import 'main.dart'; // MainPage가 정의된 파일

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 위젯이 완전히 빌드된 후에 네비게이션 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InitSelectPage1(),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset('assets/icons/알림it_ICT로고.svg'),
      ),
    );
  }
}