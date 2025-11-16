class Answer {
  String id;
  String questionId;
  String text;
  bool isCorrect;

  Answer({
    required this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['questionId'],
      text: json['text'],
      isCorrect: json['isCorrect'],
    );
  }
}