import 'package:KmerLingo/data/models/answer.dart';

class Question {
  String id;
  String lessonId;
  String languageId;
  String text;
  String? audioPath;
  String? imagePath;
  int order;
  List<Answer> answers;

  Question({
    required this.id,
    required this.lessonId,
    required this.languageId,
    required this.text,
    this.audioPath,
    this.imagePath,
    required this.order,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      lessonId: json['lessonId'],
      languageId: json['languageId'],
      text: json['text'],
      audioPath: json['audioPath'],
      imagePath: json['imagePath'],
      order: json['order'],
      answers: json['answers'] != null
          ? (json['answers'] as List).map((a) => Answer.fromJson(a)).toList()
          : [],
    );
  }
}
