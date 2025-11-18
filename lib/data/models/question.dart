import 'package:KmerLingo/data/models/answer.dart';

enum QuestionType {
  TEXT,
  MULTIPLE_CHOICE,
  AUDIO_TO_TEXT,
  AUDIO_TO_TRANSLATION,
}

QuestionType questionTypeFromString(String value) {
  switch (value) {
    case "TEXT":
      return QuestionType.TEXT;
    case "MULTIPLE_CHOICE":
      return QuestionType.MULTIPLE_CHOICE;
    case "AUDIO_TO_TEXT":
      return QuestionType.AUDIO_TO_TEXT;
    case "AUDIO_TO_TRANSLATION":
      return QuestionType.AUDIO_TO_TRANSLATION;
    default:
      return QuestionType.TEXT;
  }
}

String questionTypeToString(QuestionType type) {
  return type.toString().split('.').last;
}

class Question {
  String id;
  String lessonId;
  String languageId;
  String text;
  String? audioPath;
  String? imagePath;
  int order;
  QuestionType type; // <-- enum
  List<Answer> answers;

  Question({
    required this.id,
    required this.lessonId,
    required this.languageId,
    required this.text,
    this.audioPath,
    this.imagePath,
    required this.order,
    required this.type,
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
      type: questionTypeFromString(json['type']), // <-- conversion automatique
      answers: json['answers'] != null
          ? (json['answers'] as List)
              .map((a) => Answer.fromJson(a))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'languageId': languageId,
      'text': text,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'order': order,
      'type': questionTypeToString(type), // <-- conversion enum → String
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}
