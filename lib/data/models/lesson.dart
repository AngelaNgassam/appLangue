// import 'package:KmerLingo/data/models/question.dart';

// class Lesson {
//   String id;
//   String chapterId;
//   String title;
//   String objective;
//   int order;
//   String languageId; // <-- Champ ajouté pour la langue maternelle
//   List<Question> questions;

//   // ✅ Nouveau champ pour savoir si la leçon est complétée par l'utilisateur
//   bool isCompleted;

//   Lesson({
//     required this.id,
//     required this.chapterId,
//     required this.title,
//     required this.objective,
//     required this.order,
//     required this.languageId, // <-- ajouté
//     required this.questions,
//     this.isCompleted = false, // valeur par défaut false
//   });

//   factory Lesson.fromJson(Map<String, dynamic> json) {
//     return Lesson(
//       id: json['id'],
//       chapterId: json['chapterId'],
//       title: json['title'],
//       objective: json['objective'],
//       order: json['order'],
//       languageId: json['languageId'] ?? 'default', // <-- récupère la langue depuis le JSON, 'default' si absent
//       questions: json['questions'] != null
//           ? (json['questions'] as List)
//               .map((q) => Question.fromJson(q))
//               .toList()
//           : [],
//       isCompleted: json['isCompleted'] ?? false, // <-- récupère le statut si présent
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'chapterId': chapterId,
//       'title': title,
//       'objective': objective,
//       'order': order,
//       'languageId': languageId,
//       'questions': questions.map((q) => q.toJson()).toList(),
//       'isCompleted': isCompleted, // <-- inclut le statut dans le JSON
//     };
//   }
// }

import 'package:KmerLingo/data/models/question.dart';

class Lesson {
  String id;
  String chapterId;
  String title;
  String objective;
  int order;
  String languageId; // <-- Champ ajouté pour la langue maternelle
  List<Question> questions;

  Lesson({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.objective,
    required this.order,
    required this.languageId, // <-- ajouté
    required this.questions,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      chapterId: json['chapterId'],
      title: json['title'],
      objective: json['objective'],
      order: json['order'],
      languageId: json['languageId'] ?? 'default', // <-- récupère la langue depuis le JSON, 'default' si absent
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => Question.fromJson(q))
              .toList()
          : [],
    );
  }
}
