import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notification_it/init_selecet_page.dart';

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 150,),
          // PageView는 Expanded로 감싸야 정상 작동
          Expanded(
            child: PageView(
              children: [
                Center(child: Column(children: [Image.asset('assets/icons/알림it_init.png'),SizedBox(height: 50,),Center(child: Text('간편하게',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Center(child: Text('확인하는 학부 공지사항',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Spacer(),SvgPicture.asset('assets/icons/알림it_page_1.svg')],)),
                Center(child: Column(children: [Image.asset('assets/icons/알림it_init.png'),SizedBox(height: 50,),Center(child: Text('간편하게',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Center(child: Text('확인하는 학부 공지사항',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Spacer(),SvgPicture.asset('assets/icons/알림it_page_2.svg')],)),
                Center(child: Column(children: [Image.asset('assets/icons/알림it_init.png'),SizedBox(height: 50,),Center(child: Text('간편하게',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Center(child: Text('확인하는 학부 공지사항',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Spacer(),SvgPicture.asset('assets/icons/알림it_page_3.svg')],)),
                Center(child: Column(children: [Image.asset('assets/icons/알림it_init.png'),SizedBox(height: 50,),Center(child: Text('간편하게',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Center(child: Text('확인하는 학부 공지사항',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),Spacer(),SvgPicture.asset('assets/icons/알림it_page_4.svg')],)),
              ],
            ),
          ),

          // 버튼 영역 (Expanded 제거)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InitSelectPage1()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xff009D72),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        '시작하기',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    SystemNavigator.pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Color(0xff009D72))
                    ),
                    child: const Center(
                      child: Text(
                        '종료',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30,)
        ],
      ),
    );
  }
}