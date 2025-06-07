import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeywordPage extends StatefulWidget{
  @override
  _KeywordPage createState() => _KeywordPage();
}

class _KeywordPage extends State<KeywordPage>{

  List<String> _keywordList = [];

  String _searchText = '';
  String _selectedText = '';
  final TextEditingController _controller = TextEditingController();
  Widget SearchForm() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: TextFormField(
            controller: _controller,
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
                enabledBorder: InputBorder.none),
          ),
        ),
        Expanded(
            flex: 1,
            child: GestureDetector(
                onTap: (){
                  if (_searchText.trim().isNotEmpty) {
                  setState(() {
                    _keywordList.add(_searchText.trim());
                    _controller.clear();
                  });
                }},
                child: Text(
                  '등록',
                  style: TextStyle(color: Color(0xff009D72), fontWeight: FontWeight.bold),
                )))
      ],
    );
  }
  Widget keywordelement(String name){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 7,horizontal: 0),
      child: Row(
        children: [
          Text(name),
          Spacer(),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("'$_selectedText'키워드 알림을 삭제할까요?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 50),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: (){
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  decoration: BoxDecoration(
                                      color: Color(0xffE7E8ED),
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Center(child: Text('취소', style: TextStyle(fontWeight: FontWeight.bold),),),
                                ),
                              ),
                            ),
                            SizedBox(width: 15,),
                            Expanded(
                              child: GestureDetector(
                                onTap: (){
                                  setState(() {
                                    _keywordList.remove(name);
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  decoration: BoxDecoration(
                                      color: Color(0xff009D72),
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Center(child: Text('삭제',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: SvgPicture.asset('assets/icons/알림it_trash.svg'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(30, 80, 30, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 뒤로가기 + 스위치
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios_new_sharp, size: 20),
                      SizedBox(width: 5),
                      Text(
                        '키워드 알림 설정',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 70,
                    ),
                    SearchForm(),
                    Container(height: 2, color: Color(0xff009D72)),
                    SizedBox(height: 10,),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _keywordList.length,
                        itemBuilder: (context,index){
                          return keywordelement(_keywordList[index]);
                        },
                      )
                    ),
                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }
}