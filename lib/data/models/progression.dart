class Progression {
  String id;
  String userId;
  String questionId;
  String lessonId;
  String? userAnswer;
  String? userVoicePath;
  bool isCorrect;
  bool completed;
  DateTime answeredAt;
  String languageId;

  Progression({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.lessonId,
    this.userAnswer,
    this.userVoicePath,
    required this.isCorrect,
    required this.completed,
    required this.answeredAt,
    required this.languageId,
  });

  factory Progression.fromJson(Map<String, dynamic> json) {
    return Progression(
      id: json['id'],
      userId: json['userId'],
      questionId: json['questionId'],
      lessonId: json['lessonId'],
      userAnswer: json['userAnswer'],
      userVoicePath: json['userVoicePath'],
      isCorrect: json['isCorrect'],
      completed: json['completed'],
      answeredAt: DateTime.parse(json['answeredAt']),
      languageId: json['languageId'],
    );
  }
}
