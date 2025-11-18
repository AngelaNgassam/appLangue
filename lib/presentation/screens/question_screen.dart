import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../data/models/lesson.dart';
import '../../data/models/question.dart';
import '../../data/models/answer.dart';
import '../../core/services/api_service.dart';

class QuestionScreen extends StatefulWidget {
  final Lesson lesson;
  const QuestionScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Question>> _questionsFuture;

  // 🔊 AudioPlayers séparés
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _losePlayer = AudioPlayer();

  int _currentIndex = 0;
  bool? _isCorrect;
  String? _selectedChoice;
  late TextEditingController _answerController;
  List<String> _correctAnswers = [];

  @override
  void initState() {
    super.initState();
    _questionsFuture = apiService.getQuestionsByLesson(widget.lesson.id);
    _answerController = TextEditingController();
    _preloadSounds();
  }

  Future<void> _preloadSounds() async {
    try {
      await _winPlayer.setSource(AssetSource("win_question.mp3"));
      await _losePlayer.setSource(AssetSource("lost.mp3"));
    } catch (e) {
      print("Erreur préchargement audio: $e");
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    super.dispose();
  }

  // 🔊 Jouer le son selon correct / incorrect
  Future<void> _playSound(bool isCorrect) async {
    try {
      final player = isCorrect ? _winPlayer : _losePlayer;
      await player.stop(); // stopper si déjà en lecture
      await player.play(AssetSource(isCorrect ? "win_question.mp3" : "lost.mp3"));
    } catch (e) {
      print("Erreur audio: $e");
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _isCorrect = null;
      _correctAnswers = [];
      _answerController.clear();
    });
  }

  void _submitAnswer(Question question) async {
    final answerToSend = question.type == QuestionType.MULTIPLE_CHOICE
        ? _selectedChoice
        : _answerController.text.trim();

    if (answerToSend == null || answerToSend.isEmpty) return;

    try {
      final result = await apiService.checkAnswer(question.id, answerToSend);

      List<String> correctAnswersFromApi = [];
      if (result['correctAnswers'] != null && result['correctAnswers'] is List) {
        correctAnswersFromApi =
            List<String>.from(result['correctAnswers'].map((e) => e.toString()));
      }

      setState(() {
        _isCorrect = result['isCorrect'] ?? false;
        _correctAnswers = correctAnswersFromApi;
      });

      // 🔊 Jouer le son après setState
      _playSound(_isCorrect!);
    } catch (e) {
      print("❌ Erreur: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la validation")),
      );
    }
  }

  Widget _buildMultipleChoice(Question question) {
    return Column(
      children: question.answers.map((answer) {
        final answerText = answer.text ?? "";
        final isSelected = _selectedChoice == answerText;
        final isCorrectAnswer = _correctAnswers.contains(answerText);

        Color getColor() {
          if (_isCorrect == null) {
            return isSelected ? Colors.blue.shade100 : Colors.white;
          } else {
            if (isCorrectAnswer) return Colors.green.shade300;
            if (isSelected && !isCorrectAnswer) return Colors.red.shade300;
            return Colors.white;
          }
        }

        return GestureDetector(
          onTap: _isCorrect == null
              ? () {
                  setState(() {
                    _selectedChoice = answerText;
                  });
                }
              : null,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: getColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              answerText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text(widget.lesson.title),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune question.'));
          }

          final questions = snapshot.data!;
          if (_currentIndex >= questions.length) {
            return const Center(
              child: Text(
                "🎉 Leçon terminée !",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          }

          final question = questions[_currentIndex];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Question ${_currentIndex + 1}/${questions.length}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  question.text,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 25),
                if (question.type == QuestionType.MULTIPLE_CHOICE)
                  _buildMultipleChoice(question),
                if (question.type == QuestionType.TEXT ||
                    question.type == QuestionType.AUDIO_TO_TEXT ||
                    question.type == QuestionType.AUDIO_TO_TRANSLATION)
                  TextField(
                    controller: _answerController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Votre réponse",
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isCorrect == null
                      ? () => _submitAnswer(question)
                      : _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isCorrect == null ? Colors.green : Colors.blue,
                  ),
                  child: Text(_isCorrect == null ? "Valider" : "Suivant"),
                ),
                const SizedBox(height: 20),
                if (_isCorrect != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCorrect! ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isCorrect!
                              ? "🎉 Bonne réponse !"
                              : "❌ Mauvaise réponse",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_isCorrect! && _correctAnswers.isNotEmpty)
                        Text(
                          "✅ Réponses correctes : ${_correctAnswers.join(', ')}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
