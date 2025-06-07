import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'main.dart';

class CategoryPage extends StatefulWidget {
  CategoryPage({required this.selectedMajor});

  final String selectedMajor;

  @override
  _CategoryPageState createState() => _CategoryPageState();
}


class _CategoryPageState extends State<CategoryPage>{
  String _isSelected = '';
  String _searchText = '';

  final Map<String, List<String>> majorMap = {
    "미래엔지니어링융합대학": ["ICT융합학부", '미래모빌리티공학부','에너지화학공학부','신소재·반도체융합학부','전기전자융합학부','바이오매디컬헬스학부'],
    '스마트도시융합대학': ['건축·도시환경학부','디자인융합학부','스포츠과학부'],
    '경영·공공정책대학': ['공공인재학부','경영경제융합학부'],
    '인문예술대학': ['글로벌인문학부','예술학부'],
    '의과대학':['의예과[의학과]','간호학과'],
    '아산아너스칼리지':['자율전공학부'],
    '울산대학교':['SW사업단','U-STAR'],
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
      margin: EdgeInsets.only(top: 36),
      child: Row(
        children: [Text(name,style: TextStyle( fontSize: 17),), Spacer(), GestureDetector(
          onTap: () {
            setState(() {
              if (_isSelected==name){
                _isSelected = '';
              }else{
                _isSelected=name;}
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
  void initState(){
    _isSelected = widget.selectedMajor;
  }

  @override
  Widget build(BuildContext context){

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
        filteredList.add(SizedBox(height: 60));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 100, 30, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context)=>MainPage(selectedMajor: _isSelected,))
                      );},
                    child: Text(''
                      '⟨ 전공 선택',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),),),
                  Spacer(),
                  Column(
                    children: [
                      if (_isSelected != '') ...[
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainPage(selectedMajor: _isSelected,),
                              ),
                            );
                          },
                          child: Text(
                            '완료',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff009D72),
                            ),
                          ),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ), //헤더
            SizedBox(height: 40,),
            SearchForm(),
            Container(height: 2, color: Color(0xff009D72),),
            SizedBox(height: 60,),
            Expanded(
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