import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:notification_it/main.dart';

class InitSelectPage1 extends StatefulWidget{
  const InitSelectPage1({super.key});

  @override
  _InitSelectPage1State createState() => _InitSelectPage1State();
}

class _InitSelectPage1State extends State<InitSelectPage1>{
  String _isSelected = '';
  String _searchText = '';

  final Map<String, List<String>> majorMap = {
    "미래엔지니어링융합대학": ["ICT융합학부"],
    "IT융합학부": ["IT융합전공", "AI융합전공"],
  };

  Widget SearchForm(){
    return Row(
      children: [
        Expanded(flex: 7, child: TextFormField(
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
            enabledBorder: InputBorder.none
        ),),),
        Expanded(flex: 1,child: GestureDetector(onTap: (){}, child: Text('검색', style: TextStyle(color: Color(0xff009D72)),)))
      ],
    );
  }
  Widget Selector(String name){
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Row(
        children: [Text(name), Spacer(), GestureDetector(
      onTap: () {
        setState(() {
          _isSelected=name;
        });
      },
      child: _isSelected==name
          ? SvgPicture.asset(
        'assets/icons/알림it_checkButton_O.svg',
      )
          : SvgPicture.asset(
        'assets/icons/알림it_checkButton_X.svg',
      ),
    )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    List<Widget> majorSelector = [
      Text('미래엔지니어링융합대학', style: TextStyle(color: Color(0xff009D72),fontSize: 12, fontWeight: FontWeight.bold),),
      Selector('ICT융합학부'),
      SizedBox(height: 50,),
      Text('IT융합학부', style: TextStyle(color: Color(0xff009D72),fontSize: 12, fontWeight: FontWeight.bold),),
      Selector('IT융합전공'),
      Selector('AI융합전공'),
    ];

    List<Widget> filteredList = [];
    majorMap.forEach((faculty, majors) {
      // 전공 중 검색 키워드가 포함된 게 있는지 확인
      final matchedMajors = majors.where((m) => m.contains(_searchText)).toList();
      if (matchedMajors.isNotEmpty) {
        filteredList.add(Text(faculty,
            style: TextStyle(
                color: Color(0xff009D72),
                fontSize: 12,
                fontWeight: FontWeight.bold)));
        filteredList.addAll(matchedMajors.map((major) => Selector(major)));
        filteredList.add(SizedBox(height: 20));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 170, 30, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text('공지를 확인할 전공을\n선택해주세요!', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                    Text('학과는 언제든지 또 변경할 수 있어요.', style: TextStyle(color: Color(0xff495258), fontSize: 12),)
                  ],),
                  Spacer(),
                  Column(
                    children: [
                      TextButton(onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>InitSelectPage2(_isSelected)));
                      }, child: Text('다음', style: TextStyle(fontWeight:FontWeight.bold,color: Color(0xff009D72)),)),
                      SizedBox(height: 40,)
                    ],
                  )
                ],
              ),
            ), //헤더
            SizedBox(height: 40,),
            SearchForm(),
            Container(height: 2, color: Color(0xff009D72),),
            SizedBox(height: 60,),
            Container(height: 300,
            child: ListView(
              padding: EdgeInsets.zero,
              children: filteredList
              )
              ,),
          ],
        ),
      ),
    );
  }
}

class InitSelectPage2 extends StatefulWidget{

  String selected_major = 'ICT융합학부';

  InitSelectPage2(this.selected_major);

  @override
  _InitSelectPage2State createState() {
    return _InitSelectPage2State();
  }
}

class _InitSelectPage2State extends State<InitSelectPage2>{
  String _isSelected = '';

  Map<String, List<String>> Major = {
    "미래엔지니어링융합대학" : ["ICT융합학부"],
    "IT융합학부" : ["IT융합전공", "AI융합전공"]
  };

  Widget major_select() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: Major.entries.map((entry) {
          String faculty = entry.key; // 학부명
          List<String> majors = entry.value; // 전공 리스트

          return ListView(
            children: [
              Text(faculty, style: TextStyle(color: Color(0xff009D72), fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              ...majors.map((major) => Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 5.0),
                child: Row(
                  children: [
                    Text(major,style: TextStyle(fontSize: 30),),
                    Spacer(),
                    GestureDetector(
                      onTap: (){setState(() {
                        _isSelected = major;
                      });},
                      child: _isSelected==major
                          ? SvgPicture.asset(
                        'assets/icons/알림it_checkButton_O.svg',
                      )
                          : SvgPicture.asset(
                        'assets/icons/알림it_checkButton_X.svg',
                      ),
                    )
                  ],
                ),
              )),
              SizedBox(height: 20.0),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 100, 15, 5),
        child: Column(
          children: [
            Container(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('공지알림을 받을 전공을\n선택해주세요!', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                      Text('새로운 공지가 올라오면 알림을 보내드려요.\n알림채널은 언제든지 또 변경할 수 있어요.', style: TextStyle(color: Color(0xff495258), fontSize: 12),)
                    ],),
                  Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>MainPage(title: '알림it')));
                      }, child: Text('다음', style: TextStyle(color: Color(0xff009D72), fontWeight: FontWeight.bold),)),
                      SizedBox(height: 70,)
                    ],
                  )
                ],
              ),
            ), //헤더
            SizedBox(height: 40,),
            Container(height: 50,),
            SizedBox(height: 40,),
            Container(height: 300,)
          ],
        ),
      ),
    );
  }
}