import 'dart:async';
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
  final AudioPlayer _achievementPlayer = AudioPlayer();

  // 🔊 TTS
  late FlutterTts _flutterTts;

  int _currentIndex = 0;
  bool? _isCorrect;
  String? _selectedChoice;
  late TextEditingController _answerController;
  List<String> _correctAnswers = [];
  bool _hasSpoken = false;

  // 💰 Points animés
  int _totalLessonPoints = 0;
  int _animatedPoints = 0;
  bool _lessonFinished = false;

  // ⏱️ Temps passé
  late DateTime _startTime;
  Duration? _timeSpent;

  // 📝 Gestion des questions ratées
  List<Question> _incorrectQuestions = [];
  bool _isReviewMode = false;
  bool _firstPassComplete = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _questionsFuture = apiService.getQuestionsByLesson(widget.lesson.id);
    _answerController = TextEditingController();
    _preloadSounds();

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("fr-FR");
    _flutterTts.setSpeechRate(0.9);
    _flutterTts.setPitch(1.0);
  }

  Future<void> _preloadSounds() async {
    await _winPlayer.setSource(AssetSource("win_question.mp3"));
    await _losePlayer.setSource(AssetSource("lost.mp3"));
    await _achievementPlayer.setSource(AssetSource("achievement.mp3"));
  }

  @override
  void dispose() {
    _answerController.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    _questionAudioPlayer.dispose();
    _achievementPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _playSound(bool isCorrect) async {
    final player = isCorrect ? _winPlayer : _losePlayer;
    await player.stop();
    await player.play(AssetSource(isCorrect ? "win_question.mp3" : "lost.mp3"));
  }

  Future<void> _playAchievementSound() async {
    await _achievementPlayer.stop();
    await _achievementPlayer.play(AssetSource("achievement.mp3"));
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _playQuestionAudio(Question question) async {
    if (question.audioPath != null && question.audioPath!.isNotEmpty) {
      final url = "http://localhost:3000/${question.audioPath}";
      await _questionAudioPlayer.stop();
      await _questionAudioPlayer.play(UrlSource(url));
    } else {
      await _speakText(question.text);
    }
  }

  void _nextQuestion() {
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
        ? (_selectedChoice ?? "")
        : _answerController.text.trim();
    if (answerToSend.isEmpty) return;

    // Ne faire l'appel API que si ce n'est PAS le mode révision
    if (!_isReviewMode) {
      final result = await apiService.checkAnswer(question.id, answerToSend);

      List<String> correctAnswersFromApi = [];
      if (result['correctAnswers'] != null &&
          result['correctAnswers'] is List) {
        correctAnswersFromApi = List<String>.from(
          result['correctAnswers'].map((e) => e.toString()),
        );
      }

      setState(() {
        _isCorrect = result['isCorrect'] ?? false;
        _correctAnswers = correctAnswersFromApi;

        if (result['totalLessonPoints'] != null) {
          _totalLessonPoints = (result['totalLessonPoints'] as num).toInt();
        }

        // Ajouter la question aux questions ratées si incorrecte
        if (!_isCorrect! && !_incorrectQuestions.contains(question)) {
          _incorrectQuestions.add(question);
        }
      });

      await _playSound(_isCorrect!);

      final questions = await _questionsFuture;
      if (_currentIndex + 1 >= questions.length) {
        _firstPassComplete = true;

        // Si des questions ratées, proposer la révision
        if (_incorrectQuestions.isNotEmpty) {
          _showReviewDialog();
        } else {
          // Sinon, terminer directement
          _timeSpent = DateTime.now().difference(_startTime);
          _animatePoints();
        }
      }
    } else {
      // Mode révision : vérification locale sans appel API
      final isCorrectLocal = _checkAnswerLocally(question, answerToSend);

      List<String> correctAnswersLocal = question.answers
          .where((a) => a.isCorrect)
          .map((a) => a.text)
          .toList();

      setState(() {
        _isCorrect = isCorrectLocal;
        _correctAnswers = correctAnswersLocal;
      });

      await _playSound(_isCorrect!);

      // Passer à la question suivante en mode révision
      if (_currentIndex + 1 >= _incorrectQuestions.length) {
        // Fin de la révision
        _timeSpent = DateTime.now().difference(_startTime);
        _animatePoints();
      }
    }
  }

  bool _checkAnswerLocally(Question question, String userAnswer) {
    if (question.type == QuestionType.MULTIPLE_CHOICE) {
      final correctAnswer = question.answers.firstWhere(
        (a) => a.isCorrect,
        orElse: () => Answer(
          id: "0",
          questionId: question.id,
          text: "",
          isCorrect: false,
        ),
      );
      return correctAnswer.text.trim().toLowerCase() ==
          userAnswer.trim().toLowerCase();
    } else {
      // Pour les questions textuelles, vérifier si la réponse correspond à une des réponses correctes
      return question.answers.any(
        (a) =>
            a.isCorrect &&
            a.text.trim().toLowerCase() == userAnswer.trim().toLowerCase(),
      );
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Révision"),
        content: Text(
          "Vous avez ${_incorrectQuestions.length} question(s) incorrecte(s).\n\n"
          "Voulez-vous les réviser maintenant ?\n\n"
          "⚠️ Note : La révision ne changera pas vos résultats.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _timeSpent = DateTime.now().difference(_startTime);
              _animatePoints();
            },
            child: const Text("Non, terminer"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startReviewMode();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Oui, réviser"),
          ),
        ],
      ),
    );
  }

  void _startReviewMode() {
    setState(() {
      _isReviewMode = true;
      _currentIndex = 0;
      _selectedChoice = null;
      _isCorrect = null;
      _correctAnswers = [];
      _answerController.clear();
      _hasSpoken = false;
    });
  }

  void _animatePoints() {
    setState(() {
      _lessonFinished = true;
    });
    _animatedPoints = 0;
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_animatedPoints >= _totalLessonPoints) {
        timer.cancel();
      } else {
        setState(() {
          _animatedPoints += (_totalLessonPoints / 50).ceil();
          if (_animatedPoints > _totalLessonPoints) {
            _animatedPoints = _totalLessonPoints;
          }
        });
      }
    });
    _playAchievementSound();
  }

  Widget _buildMultipleChoice(Question question) {
    return Column(
      children: question.answers.map((answer) {
        final answerText = answer.text;
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

  Widget _buildResultsScreen() {
    final minutes = _timeSpent?.inMinutes ?? 0;
    final seconds = (_timeSpent?.inSeconds ?? 0) % 60;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Trophée animé
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Icon(
                        Icons.emoji_events,
                        size: 120,
                        color: Colors.amber,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Titre
                const Text(
                  "Félicitations !",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Leçon terminée",
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // Carte des résultats
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Points obtenus
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.amber,
                            size: 40,
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Points obtenus",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "$_animatedPoints XP",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Temps passé
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.blue,
                              size: 30,
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Temps passé",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "${minutes}min ${seconds}s",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // Bouton Continuer
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Continuer",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _lessonFinished
          ? null
          : AppBar(
              backgroundColor: _isReviewMode
                  ? Colors.orange.shade600
                  : Colors.green.shade600,
              title: Text(
                _isReviewMode
                    ? "Révision - ${widget.lesson.title}"
                    : widget.lesson.title,
              ),
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

          // Écran de fin de leçon
          if (_lessonFinished) {
            return _buildResultsScreen();
          }

          // Déterminer la liste de questions à utiliser
          final questions = _isReviewMode
              ? _incorrectQuestions
              : snapshot.data!;

          // Question en cours
          if (_currentIndex >= questions.length) return const SizedBox();

          final question = questions[_currentIndex];

          if (!_hasSpoken) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _playQuestionAudio(question);
              _hasSpoken = true;
            });
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge mode révision
                  if (_isReviewMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 16, color: Colors.orange),
                          SizedBox(width: 5),
                          Text(
                            "Mode Révision - Ne compte pas",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    "Question ${_currentIndex + 1}/${questions.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                        icon: Icon(
                          Icons.volume_up,
                          color: _isReviewMode ? Colors.orange : Colors.green,
                        ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCorrect == null
                          ? () => _submitAnswer(question)
                          : _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCorrect == null
                            ? (_isReviewMode ? Colors.orange : Colors.green)
                            : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isCorrect == null ? "Valider" : "Suivant",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_isCorrect! && _correctAnswers.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              "✅ Réponse(s) correcte(s) : ${_correctAnswers.join(', ')}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
