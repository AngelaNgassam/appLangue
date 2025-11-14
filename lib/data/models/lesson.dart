import 'package:KmerLingo/data/models/question.dart';

class Lesson {
  String id;
  String chapterId;
  String title;
  String objective;
  int order;
  List<Question> questions;

  Lesson({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.objective,
    required this.order,
    required this.questions,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      chapterId: json['chapterId'],
      title: json['title'],
      objective: json['objective'],
      order: json['order'],
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => Question.fromJson(q))
              .toList()
          : [],
    );
  }
}