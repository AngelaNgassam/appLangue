import 'package:KmerLingo/data/models/lesson.dart';

class Chapter {
  String id;
  String moduleId;
  String title;
  String objective;
  int order;
  List<Lesson> lessons;

  Chapter({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.objective,
    required this.order,
    required this.lessons,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      moduleId: json['moduleId'],
      title: json['title'],
      objective: json['objective'],
      order: json['order'],
      lessons: json['lessons'] != null
          ? (json['lessons'] as List).map((l) => Lesson.fromJson(l)).toList()
          : [],
    );
  }
}