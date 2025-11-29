import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  // 🔊 AudioPlayers
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _losePlayer = AudioPlayer();
  final AudioPlayer _questionAudioPlayer = AudioPlayer();

  // 🔊 TTS
  late FlutterTts _flutterTts;

  int _currentIndex = 0;
  bool? _isCorrect;
  String? _selectedChoice;
  late TextEditingController _answerController;
  List<String> _correctAnswers = [];

  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    print("📌 initState called for lesson id: ${widget.lesson.id}");
    _questionsFuture = apiService.getQuestionsByLesson(widget.lesson.id);
    _answerController = TextEditingController();
    _preloadSounds();

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("fr-FR");
    _flutterTts.setSpeechRate(0.9);
    _flutterTts.setPitch(1.0);
    print("🎤 TTS initialized");
  }

  Future<void> _preloadSounds() async {
    try {
      print("🔊 Preloading win/lose sounds...");
      await _winPlayer.setSource(AssetSource("win_question.mp3"));
      await _losePlayer.setSource(AssetSource("lost.mp3"));
      print("✅ Sounds preloaded successfully");
    } catch (e) {
      print("❌ Error preloading sounds: $e");
    }
  }

  @override
  void dispose() {
    print("🧹 Disposing resources...");
    _answerController.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    _questionAudioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      print("🔊 Playing sound, isCorrect: $isCorrect");
      final player = isCorrect ? _winPlayer : _losePlayer;
      await player.stop();
      await player.play(AssetSource(isCorrect ? "win_question.mp3" : "lost.mp3"));
      print("✅ Sound played successfully");
    } catch (e) {
      print("❌ Error playing sound: $e");
    }
  }

  Future<void> _speakText(String text) async {
    try {
      print("🗣️ Speaking text via TTS: $text");
      await _flutterTts.stop();
      await _flutterTts.speak(text);
      print("✅ TTS done");
    } catch (e) {
      print("❌ Error in TTS: $e");
    }
  }

  Future<void> _playQuestionAudio(Question question) async {
    try {
      print("🎧 Attempting to play question audio: ${question.audioPath}");
      if (question.audioPath != null && question.audioPath!.isNotEmpty) {
        final url = "http://localhost:3000/${question.audioPath}";
        print("🔗 Audio URL: $url");
        await _questionAudioPlayer.stop();
        await _questionAudioPlayer.play(UrlSource(url));
        print("✅ Audio played successfully from URL");
      } else {
        print("ℹ️ No audioPath found, falling back to TTS");
        await _speakText(question.text);
      }
    } catch (e) {
      print("❌ Error playing question audio: $e");
    }
  }

  void _nextQuestion() {
    print("➡️ Moving to next question");
    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _isCorrect = null;
      _correctAnswers = [];
      _answerController.clear();
      _hasSpoken = false;
    });
  }

  void _submitAnswer(Question question) async {
    final answerToSend = question.type == QuestionType.MULTIPLE_CHOICE
        ? _selectedChoice
        : _answerController.text.trim();

    print("📝 Submitting answer: $answerToSend for question id: ${question.id}");
    if (answerToSend == null || answerToSend.isEmpty) {
      print("⚠️ Answer is empty, skipping submission");
      return;
    }

    try {
      final result = await apiService.checkAnswer(question.id, answerToSend);
      print("📡 API result: $result");

      List<String> correctAnswersFromApi = [];
      if (result['correctAnswers'] != null && result['correctAnswers'] is List) {
        correctAnswersFromApi =
            List<String>.from(result['correctAnswers'].map((e) => e.toString()));
      }

      setState(() {
        _isCorrect = result['isCorrect'] ?? false;
        _correctAnswers = correctAnswersFromApi;
      });

      print("✅ Answer processed, isCorrect: $_isCorrect, correctAnswers: $_correctAnswers");

      await _playSound(_isCorrect!);
    } catch (e) {
      print("❌ Error submitting answer: $e");
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
                  print("✅ Choice selected: $answerText");
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
    print("📱 Building QuestionScreen widget");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text(widget.lesson.title),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          print("📡 FutureBuilder snapshot: connectionState=${snapshot.connectionState}");
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("⏳ Waiting for questions...");
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("❌ FutureBuilder error: ${snapshot.error}");
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print("⚠️ No questions found");
            return const Center(child: Text('Aucune question.'));
          }

          final questions = snapshot.data!;
          print("✅ Questions fetched: ${questions.length}");

          if (_currentIndex >= questions.length) {
            print("🎉 Lesson finished");
            return const Center(
              child: Text(
                "🎉 Leçon terminée !",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          }

          final question = questions[_currentIndex];
          print("📖 Current question index: $_currentIndex, id: ${question.id}");

          if (!_hasSpoken) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print("🔊 Playing audio/TTS for question index $_currentIndex");
              _playQuestionAudio(question);
              _hasSpoken = true;
            });
          }

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.text,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.green),
                      onPressed: () => _playQuestionAudio(question),
                    ),
                  ],
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
