import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Row(children: [
              SizedBox(
                width: 15,
              ),
              Icon(
                Icons.arrow_back_ios_new_sharp,
                size: 20,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                '전공 선택',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              )
            ]),
          ),
          SizedBox(
            height: 15,
          ),
          Text(
            '미래엔지니어링 융합대학',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(35, 15, 15, 5),
                    child: GestureDetector(
                                    onTap: () {
                                      print('ICT융합학부 선택');
                                    },
                                    child: Row(children: [
                    SvgPicture.asset('assets/icons/알림it_ICT융합학부_logo.svg'),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'ICT융합학부',
                      style: TextStyle(fontSize: 18),
                    )
                                    ]),
                                  ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(30, 15, 15, 5),
                    child: GestureDetector(
                                    onTap: () {
                    print('AI융합전공 선택');
                                    },
                                    child: Row(children: [
                    SvgPicture.asset('assets/icons/알림it_AI융합전공_logo.svg'),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'AI융합학부',
                      style: TextStyle(fontSize: 18),
                    )
                                    ]),
                                  ),
                  ),],),
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(30, 15, 15, 5),
                    child: GestureDetector(
                                    onTap: () {
                                      print('IT융합전공 선택');
                                    },
                                    child: Row(children: [
                    SvgPicture.asset('assets/icons/알림it_IT융합학부_logo.svg'),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'IT융합전공',
                      style: TextStyle(fontSize: 18),
                    )
                                    ]),
                                  ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
