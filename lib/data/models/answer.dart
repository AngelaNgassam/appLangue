class Answer {
  String id;
  String questionId;
  String? text; // <-- peut être null si c'est une réponse audio
  String? audioPath; // <-- ajouté pour VOICE_TO_TEXT / AUDIO answers
  List<String> wordOptions; // 👈 NOUVEAU : mots pour construire la phrase
  bool isCorrect;

  Answer({
    required this.id,
    required this.questionId,
    this.text,
    this.audioPath,
    this.wordOptions = const [], // 👈 Par défaut, liste vide
    required this.isCorrect,
  });

  /// 🔹 Vérifie si la réponse de l'utilisateur est correcte (texte uniquement)
  bool checkUserAnswer(String userAnswer) {
    if (text == null) return false;
    return userAnswer.trim().toLowerCase() == text!.trim().toLowerCase() && isCorrect;
  }

  /// 🔹 Crée une réponse représentant l'entrée utilisateur
  factory Answer.fromUser(String userAnswer) {
    return Answer(
      id: "USER",
      questionId: "USER",
      text: userAnswer,
      audioPath: null,
      wordOptions: [], // 👈 Liste vide
      isCorrect: false,
    );
  }

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['questionId'],
      text: json['text'],
      audioPath: json['audioPath'],
      wordOptions: json['wordOptions'] != null // 👈 NOUVEAU
          ? List<String>.from(json['wordOptions'])
          : [],
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'text': text,
      'audioPath': audioPath,
      'wordOptions': wordOptions, // 👈 NOUVEAU
      'isCorrect': isCorrect,
    };
  }
}