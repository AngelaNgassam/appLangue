import 'package:KmerLingo/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../data/models/lesson.dart';
import '../../data/models/question.dart';

class QuestionScreen extends StatefulWidget {
  final Lesson lesson;
  const QuestionScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Question>> _questionsFuture;
  Map<String, String> userAnswers = {}; // questionId -> answer text

  @override
  void initState() {
    super.initState();
    _questionsFuture = fetchQuestions();
  }

  Future<List<Question>> fetchQuestions() async {
    final questionsJson = await apiService.fetchQuestions(widget.lesson.id);
    return questionsJson.map<Question>((q) => Question.fromJson(q)).toList();
  }

  void submitAnswer(String questionId, String answer) async {
    // Ici on pourrait récupérer userId et languageId depuis SharedPreferences ou contexte
    const userId = "user-id-example"; 
    const languageId = "language-id-example";

    final success = await apiService.submitAnswer(
      userId: userId,
      questionId: questionId,
      lessonId: widget.lesson.id,
      languageId: languageId,
      userText: answer,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse soumise avec succès')),
      );
      setState(() {
        userAnswers[questionId] = answer;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la soumission')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune question disponible.'));
          } else {
            final questions = snapshot.data!;
            return ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final controller = TextEditingController(
                    text: userAnswers[question.id] ?? "");
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.text,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Votre réponse',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            submitAnswer(question.id, controller.text);
                          },
                          child: const Text('Soumettre'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
