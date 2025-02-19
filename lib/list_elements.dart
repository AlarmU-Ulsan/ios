import 'package:flutter_svg/svg.dart';
import 'package:notification_it/webView.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ElementWidget extends StatefulWidget {
  final bool important;
  final String date;
  final String topic;
  final String url;


  ElementWidget({
    required this.important,
    required this.date,
    required this.topic,
    required this.url,
  });

  @override
  _ElementWidgetState createState() => _ElementWidgetState();
}

class _ElementWidgetState extends State<ElementWidget> {
  BookmarkManager bookmarkManager = BookmarkManager();
  bool _isBookmarked = false;
  late Future<bool> _isBookmarkedFuture;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
    _isBookmarkedFuture = BookmarkManager.isBookmarked(widget.date, widget.topic);
  }

  Future<void> _loadBookmarkStatus() async {
    bool bookmarked = await BookmarkManager.isBookmarked(widget.date, widget.topic);
    setState(() {
      _isBookmarked = bookmarked;
    });
  }

  void _toggleBookmark() async {
    await BookmarkManager.toggleBookmark(widget.date, widget.topic);
    setState(() {
      _isBookmarked = !_isBookmarked; // 즉시 상태 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(url: widget.url),
          ),
        );
      },
      child: SizedBox(
        width: 315,
        height: 79,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15.0),
                      Row(
                        children: [
                          if (widget.important)
                            SizedBox(
                              height: 15,
                              width: 45,
                              child: Container(
                                margin: EdgeInsets.only(left:2.0, right: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: Color(0xff009D72),
                                ),
                                child: Center(
                                  child: Text(
                                    '중요',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 70,
                            height: 15,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xffEEEEEE),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Text(
                                  widget.date,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xff666666),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        widget.topic,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.42,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 15.0),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleBookmark,
                  icon: FutureBuilder<bool>(
                    future: BookmarkManager.isBookmarked(widget.date, widget.topic),
                    builder: (context, snapshot) {
                      bool isBookmarked = snapshot.data ?? false;
                      return SvgPicture.asset(
                        isBookmarked
                            ? 'assets/icons/알림it_북마크_O.svg'
                            : 'assets/icons/알림it_북마크_X.svg',
                      );
                    },
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: Color(0xffE0E0E0),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarkManager {
  static const String bookmarkKey = 'bookmarks';

  static Future<void> toggleBookmark(String date, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$date|$title';
    final bookmarks = prefs.getStringList(bookmarkKey) ?? [];

    if (bookmarks.contains(key)) {
      bookmarks.remove(key);
    } else {
      bookmarks.add(key);
    }
    await prefs.setStringList(bookmarkKey, bookmarks);
  }

  static Future<bool> isBookmarked(String date, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(bookmarkKey) ?? [];
    return bookmarks.contains('$date|$title');
  }

   Future<List<String>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(bookmarkKey) ?? [];
  }
}