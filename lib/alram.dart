import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AlarmPage extends StatefulWidget{
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage>{
  bool _isChecked = false;
  int _selectedType = 0;
  Color firstColor = Color(0xFF009D72);
  Color secondColor = Color(0xFFA3A3A3);
  int count = 0;

  Widget _type(){
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: (){
              setState(() {
                _selectedType = 0;
                firstColor = Color(0xFF009D72);
                secondColor = Color(0xFFA3A3A3);
              });
              print('게시글');
            },
            child: Column(
              children: [
                Center(
                  child: Text('게시글',style: TextStyle(color: firstColor, fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 1.5,
                  width: double.infinity,
                  color: firstColor,
                )
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: (){
              setState(() {
                _selectedType = 1;
                firstColor = Color(0xFFA3A3A3);
                secondColor = Color(0xFF009D72);
              });
              print('키워드');
            },
            child: Column(
              children: [
                Center(
                  child: Text('키워드',style: TextStyle(color: secondColor, fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 1.5,
                  width: double.infinity,
                  color: secondColor,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _keywordMid(){
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> KeywordPage()));
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(25, 20, 25, 20),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/알림it_bell_O.svg',
            ),
            SizedBox(width: 15,),
            Text('알림 받는 키워드 $count개'),
            Spacer(),
            Container(
              height: 26,
              width: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Color(0xFFEEEEEE)
              ),
              child: Center(child: Text('키워드 설정', style: TextStyle(color: Color(0xFF666666)),)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(top: 70),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 30, 0),
              child: Row(
                children: [
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
                        '알림',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      )
                    ]),
                  ),
                  Spacer(),
                  CupertinoSwitch(value: _isChecked, activeColor: Color(0xFF009D72),
                    onChanged: (bool? value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                  )
                ],
              ),
            ),
            SizedBox(height: 15,),
            _type(),
            if(_selectedType == 0)
              // ListView()
              Container()
            else if (_selectedType == 1)
              Column(
                children: [
                  _keywordMid(),
                  // ListView()
                ],
              )
          ],
        ),
      ),
    );
  }
}

class KeywordPage extends StatefulWidget{
  @override
  _KeywordPage createState() => _KeywordPage();
}

class _KeywordPage extends State<KeywordPage>{

  Widget textFormField(){
    return Container(
      margin: EdgeInsets.fromLTRB(20, 30, 20, 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: InputDecoration(
              hintText: "알림 받을 키워드를 입력해주세요.",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1.5,
            color: Color(0xff009D72),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                "등록",
                style: TextStyle(color: Color(0xff009D72)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(top: 70),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 30, 0),
              child: Row(
                children: [
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
                        '키워드 알림 설정',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      )
                    ]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30,),
            textFormField(),
          ],
        ),
      ),
    );
  }
}