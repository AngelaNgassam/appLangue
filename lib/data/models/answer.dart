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

  /// 🔹 Vérifie si la réponse de l'utilisateur est correcte
  bool checkUserAnswer(String userAnswer) {
    return userAnswer.trim().toLowerCase() ==
        text.trim().toLowerCase() &&
        isCorrect;
  }

  /// 🔹 Crée une réponse représentant l'entrée utilisateur (pas côté backend)
  factory Answer.fromUser(String userAnswer) {
    return Answer(
      id: "USER",          // Valeur par défaut
      questionId: "USER",  // Pas utilisé ici
      text: userAnswer,
      isCorrect: false,    // L'application va vérifier ensuite
    );
  }

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['questionId'],
      text: json['text'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}
