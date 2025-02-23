import 'dart:convert';

class Notice {
  final int id;
  final String title;
  final String date;
  final String link;
  final String category;

  Notice({
    required this.id,
    required this.title,
    required this.date,
    required this.link,
    required this.category,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      link: json['link'],
      category: json['category'],
    );
  }
}