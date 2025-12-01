import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Importations fictives pour la compilation
// **Assurez-vous que vos vraies classes Lesson, Question, Answer ont les propriétés utilisées (id, text, type, answers, isCorrect).**
import '../../data/models/lesson.dart'; 
import '../../data/models/question.dart';
import '../../data/models/answer.dart';
import '../../core/services/api_service.dart';

// Enum pour simuler les types de questions s'ils ne sont pas dans les imports
enum QuestionType { MULTIPLE_CHOICE, TEXT, AUDIO_TO_TEXT, AUDIO_TO_TRANSLATION }

class QuestionScreen extends StatefulWidget {
  final Lesson lesson;
  const QuestionScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> with TickerProviderStateMixin {
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

  // 📊 Animation de progression
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // 💬 Animation du panneau de feedback
  late AnimationController _feedbackController;
  late Animation<Offset> _feedbackOffsetAnimation;

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

    // Initialisation de la progression
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_progressController);


    // Initialisation du feedback
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackOffsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOutCubic,
    ));

    // Démarre l'animation de progression initiale (si des questions sont déjà là)
    _questionsFuture.then((questions) {
      if (questions.isNotEmpty) {
        // Initialise la valeur d'animation à la première question
        _updateProgress(questions.length, initial: true); 
      }
    });
  }

  void _updateProgress(int totalLength, {bool initial = false}) {
    if (totalLength > 0) {
      final target = (_currentIndex + 1) / totalLength;
      
      // Assurez-vous que l'animation est correcte si la taille change (ex: passage au mode révision)
      if (_progressAnimation.value * totalLength != _currentIndex + 1 || initial) {
        _progressAnimation = Tween<double>(
          begin: initial ? 0.0 : _progressAnimation.value,
          end: target,
        ).animate(_progressController);
        
        // Redémarre l'animation pour le nouveau segment
        if (!initial) {
            _progressController.forward(from: _progressAnimation.value);
        } else {
            // Pour le premier chargement, mettez simplement à jour la valeur.
            _progressController.value = target;
        }
      }
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    _questionAudioPlayer.dispose();
    _achievementPlayer.dispose();
    _flutterTts.stop();
    _progressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _preloadSounds() async {
    // Les sons sont préchargés ici
    // Note: Utiliser `AssetSource` si les fichiers sont dans `assets/`
    await _winPlayer.setSource(AssetSource("win_question.mp3"));
    await _losePlayer.setSource(AssetSource("lost.mp3"));
    await _achievementPlayer.setSource(AssetSource("achievement.mp3"));
  }

  Future<void> _playSound(bool isCorrect) async {
    final player = isCorrect ? _winPlayer : _losePlayer;
    await player.stop();
    // Re-joue car la source est déjà préchargée
    await player.resume(); 
  }

  Future<void> _playAchievementSound() async {
    await _achievementPlayer.stop();
    // Re-joue car la source est déjà préchargée
    await _achievementPlayer.resume();
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _playQuestionAudio(Question question) async {
    if (question.audioPath != null && question.audioPath!.isNotEmpty) {
      // Remplacez 'localhost' par votre URL de base si nécessaire
      final url = "http://localhost:3000/${question.audioPath}"; 
      await _questionAudioPlayer.stop();
      await _questionAudioPlayer.play(UrlSource(url));
    } else {
      await _speakText(question.text);
    }
  }

  void _nextQuestion() async {
    // Cache la barre de feedback
    await _feedbackController.reverse();

    // Détermine la liste de questions actuelle pour la taille
    final questionsList = _isReviewMode ? _incorrectQuestions : await _questionsFuture;

    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _isCorrect = null;
      _correctAnswers = [];
      _answerController.clear();
      _hasSpoken = false;
    });

    // Mise à jour de la progression pour la nouvelle question
    if (_currentIndex < questionsList.length) {
      _updateProgress(questionsList.length);
      // Prépare le TTS/Audio pour la nouvelle question si nécessaire
      final question = questionsList[_currentIndex];
      if (question.type == QuestionType.AUDIO_TO_TEXT || question.type == QuestionType.AUDIO_TO_TRANSLATION) {
          _playQuestionAudio(question);
      }
    } else {
      // Fin de la leçon / révision
      if (_isReviewMode) {
        // Fin du mode révision
        _timeSpent = DateTime.now().difference(_startTime);
        _animatePoints();
      } else {
        // Fin de la première passe
        if (_incorrectQuestions.isNotEmpty) {
          _showReviewDialog();
        } else {
          _timeSpent = DateTime.now().difference(_startTime);
          _animatePoints();
        }
      }
    }
  }

  void _submitAnswer(Question question) async {
    final answerToSend = question.type == QuestionType.MULTIPLE_CHOICE
        ? (_selectedChoice ?? "")
        : _answerController.text.trim();
        
    // Prévention de l'envoi d'une réponse vide
    if (answerToSend.isEmpty && question.type != QuestionType.MULTIPLE_CHOICE) return;
    if (answerToSend.isEmpty && question.type == QuestionType.MULTIPLE_CHOICE && _selectedChoice == null) return;


    // Masque le clavier si c'est une question textuelle
    FocusScope.of(context).unfocus();

    bool localIsCorrect = false;
    List<String> localCorrectAnswers = [];
    int newTotalLessonPoints = _totalLessonPoints;
    bool needsApiCall = !_isReviewMode;
    bool isFirstTimeCorrect = false;

    if (needsApiCall) {
      // Appel API pour la première passe
      final result = await apiService.checkAnswer(question.id, answerToSend);

      if (result['correctAnswers'] != null && result['correctAnswers'] is List) {
        localCorrectAnswers = List<String>.from(
          result['correctAnswers'].map((e) => e.toString()),
        );
      }
      localIsCorrect = result['isCorrect'] ?? false;
      
      if (result['totalLessonPoints'] != null) {
        newTotalLessonPoints = (result['totalLessonPoints'] as num).toInt();
      }
      
      // Stocke la question manquée si la réponse est fausse
      if (!localIsCorrect && !_incorrectQuestions.contains(question)) {
        _incorrectQuestions.add(question);
      }
      
      // Détecte si la réponse est correcte pour la première fois (si on veut marquer ce point)
      isFirstTimeCorrect = localIsCorrect; 

    } else {
      // Mode révision : vérification locale (pas d'impact sur le score)
      localIsCorrect = _checkAnswerLocally(question, answerToSend);
      localCorrectAnswers = question.answers
          .where((a) => a.isCorrect)
          .map((a) => a.text)
          .toList();

      // En mode révision, on peut retirer la question de la liste pour ne plus la revoir
      if (localIsCorrect) {
          _incorrectQuestions.remove(question);
      }
    }

    setState(() {
      _isCorrect = localIsCorrect;
      _correctAnswers = localCorrectAnswers;
      _totalLessonPoints = newTotalLessonPoints;
    });

    await _playSound(_isCorrect!);
    await _feedbackController.forward(from: 0.0);
  }
  
  // Fonction de vérification locale pour le mode révision (utilise les données client)
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
      // Pour les questions textuelles, vérifiez si la réponse utilisateur correspond à une des réponses correctes
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Révision Suggérée"),
          ],
        ),
        content: Text(
          "Vous avez ${_incorrectQuestions.length} question(s) à revoir. "
          "Voulez-vous les réviser maintenant ?\n\n"
          "Note : Le mode révision est pour l'apprentissage, il ne changera pas votre score actuel.",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _timeSpent = DateTime.now().difference(_startTime);
              _animatePoints(); // Termine la leçon sans révision
            },
            child: const Text("Non, terminer", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startReviewMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Oui, réviser", style: TextStyle(fontWeight: FontWeight.bold)),
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
    // Met à jour la progression pour la liste de révision
    _updateProgress(_incorrectQuestions.length, initial: true); 
    
    // Démarre l'audio pour la première question de révision
    if (_incorrectQuestions.isNotEmpty) {
        final question = _incorrectQuestions[_currentIndex];
        if (question.type == QuestionType.AUDIO_TO_TEXT || question.type == QuestionType.AUDIO_TO_TRANSLATION) {
            _playQuestionAudio(question);
        }
    }
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
    // ... (Code de construction des choix multiples inchangé)
    return Column(
      children: question.answers.map((answer) {
        final answerText = answer.text;
        final isSelected = _selectedChoice == answerText;
        final isCorrectAnswer = _correctAnswers.contains(answerText);
        final bool isChecked = _isCorrect != null;

        Color getColor() {
          if (!isChecked) {
            return isSelected ? (Colors.green.shade100) : Colors.white;
          } else {
            if (isCorrectAnswer) return Colors.green.shade300;
            if (isSelected && !isCorrectAnswer) return Colors.red.shade300;
            return Colors.grey.shade100; // Couleur neutre après vérification
          }
        }

        Icon? getIcon() {
          if (!isChecked) {
            return isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null;
          } else {
            if (isCorrectAnswer) return const Icon(Icons.check_circle, color: Colors.white);
            if (isSelected && !isCorrectAnswer) return const Icon(Icons.cancel, color: Colors.white);
            return null;
          }
        }

        Color getTextColor() {
          if (!isChecked) {
             return isSelected ? Colors.green.shade900 : Colors.black87;
          } else {
            if (isCorrectAnswer || (isSelected && !isCorrectAnswer)) return Colors.white;
            return Colors.black87;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: getColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isChecked
                    ? (isCorrectAnswer ? Colors.green.shade600 : Colors.red.shade600)
                    : (isSelected ? Colors.green.shade300 : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 5,
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCorrect == null
                    ? () {
                        setState(() {
                          _selectedChoice = answerText;
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          answerText,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: getTextColor(),
                          ),
                        ),
                      ),
                      if (getIcon() != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: getIcon(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(Question question) {
    // ... (Code du champ de texte inchangé)
    return TextField(
      controller: _answerController,
      enabled: _isCorrect == null,
      decoration: InputDecoration(
        labelText: "Votre réponse",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _isCorrect != null
                  ? (_isCorrect! ? Colors.green : Colors.red)
                  : Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: (_isReviewMode ? Colors.orange : Colors.green), width: 2),
        ),
        filled: true,
        fillColor: _isCorrect != null ? Colors.grey.shade50 : Colors.white,
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      onSubmitted: _isCorrect == null ? (_) => _submitAnswer(question) : null,
      style: const TextStyle(fontSize: 17),
    );
  }

  Widget _buildResultsScreen() {
    // ... (Code de l'écran de résultats inchangé)
    final minutes = _timeSpent?.inMinutes ?? 0;
    final seconds = (_timeSpent?.inSeconds ?? 0) % 60;
    final primaryColor = Colors.lightGreen.shade700;
    final secondaryColor = Colors.amber.shade700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Trophée animé
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.emoji_events,
                          size: 140,
                          color: secondaryColor,
                          shadows: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(5, 5))
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Titre
                  const Text(
                    "Leçon Complétée !",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Vous avez terminé ${widget.lesson.title}",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // Carte des résultats
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Points obtenus
                        _buildResultRow(
                          icon: Icons.stars,
                          iconColor: secondaryColor,
                          label: "Points obtenus (XP)",
                          value: _animatedPoints.toString(),
                          valueStyle: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const Divider(height: 40, thickness: 1.5),

                        // Temps passé
                        _buildResultRow(
                          icon: Icons.access_time_filled,
                          iconColor: Colors.blue.shade600,
                          label: "Temps passé",
                          value: "${minutes}min ${seconds}s",
                          valueStyle: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      "Continuer l'Apprentissage",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow({
    // ... (Code de la ligne de résultat inchangé)
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required TextStyle valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildQuestionContent(Question question, int totalQuestions) {
    // S'assurer que l'animation de progression est utilisée
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final bool isChecked = _isCorrect != null;

        return Column(
          children: [
            // Progression et points
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isReviewMode ? Colors.orange.shade600 : Colors.green.shade600,
                      ),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    '${_currentIndex + 1}/$totalQuestions',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Badge mode révision
            if (_isReviewMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 5),
                      Text(
                        "Mode Révision - Ne compte pas",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Carte de la question
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Bouton audio (s'estompe après la vérification)
                        AnimatedOpacity(
                          opacity: isChecked ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: IconButton(
                            icon: Icon(
                              Icons.volume_up,
                              size: 30,
                              color: _isReviewMode ? Colors.orange.shade600 : Colors.green.shade600,
                            ),
                            onPressed: isChecked ? null : () => _playQuestionAudio(question),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Contenu de la réponse - C'est ici que le champ de saisie est affiché !
                    if (question.type == QuestionType.MULTIPLE_CHOICE)
                      _buildMultipleChoice(question),
                    if (question.type == QuestionType.TEXT ||
                        question.type == QuestionType.AUDIO_TO_TEXT ||
                        question.type == QuestionType.AUDIO_TO_TRANSLATION)
                      _buildTextField(question),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Barre de validation et de feedback
  Widget _buildBottomBar(Question question) {
    // ... (Code de la barre du bas inchangé)
    final bool isChecked = _isCorrect != null;
    final bool canSubmit = question.type == QuestionType.MULTIPLE_CHOICE
        ? (_selectedChoice != null)
        : (_answerController.text.trim().isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panneau de Feedback (animé)
        SlideTransition(
          position: _feedbackOffsetAnimation,
          child: _isCorrect != null
              ? _buildFeedbackPanel(question)
              : const SizedBox(height: 0),
        ),

        // Bouton de navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isChecked
                  ? _nextQuestion
                  : (canSubmit ? () => _submitAnswer(question) : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: isChecked
                    ? Colors.blue.shade600
                    : (canSubmit
                        ? (_isReviewMode ? Colors.orange.shade600 : Colors.green.shade600)
                        : Colors.grey.shade400),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                isChecked ? "Continuer (Suivant)" : "Valider",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackPanel(Question question) {
    // CODE COMPLÉTÉ
    final bool isCorrect = _isCorrect ?? false;
    final Color primaryColor = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
    final String title = isCorrect ? "Excellent !" : "Mauvaise réponse";
    final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
    
    // Message si la réponse est fausse
    final String incorrectMessage = "La réponse correcte était : ${_correctAnswers.join(' / ')}";

    return Container(
      width: double.infinity,
      color: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SafeArea( // Utiliser SafeArea pour éviter les découpes
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isCorrect && _correctAnswers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  incorrectMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 👇 LA MÉTHODE BUILD PRINCIPALE AJOUTÉE
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Question>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (_lessonFinished) {
          return _buildResultsScreen();
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.lesson.title), backgroundColor: Colors.green),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Erreur"), backgroundColor: Colors.red),
            body: Center(child: Text("Erreur de chargement : ${snapshot.error}")),
          );
        }

        final questionsList = _isReviewMode ? _incorrectQuestions : (snapshot.data ?? []);
        if (questionsList.isEmpty || _currentIndex >= questionsList.length) {
          // Gère le cas où l'on arrive à la fin de la liste des questions ou qu'elle est vide
          if (_isReviewMode && _incorrectQuestions.isNotEmpty) {
            // Si c'est la fin du mode révision, mais qu'il reste des questions non corrigées
             return _buildResultsScreen(); // On termine quand même pour l'instant
          }
          if (!_isReviewMode && _incorrectQuestions.isNotEmpty) {
            // Si c'est la fin de la première passe et qu'il y a des erreurs, le dialogue prendra le relais
            // Si le dialogue n'est pas affiché, on affiche les résultats
            if (_timeSpent == null) {
               _timeSpent = DateTime.now().difference(_startTime);
               _animatePoints(); 
            }
          }
          if (!_lessonFinished) {
             return Scaffold(
              appBar: AppBar(title: Text(widget.lesson.title), backgroundColor: Colors.green),
              body: const Center(child: Text("Leçon terminée ou pas de question.")),
            );
          }
        }
        
        if (_currentIndex >= questionsList.length) {
             // Redirige vers l'écran de fin si l'index est dépassé
             return _buildResultsScreen();
        }

        final currentQuestion = questionsList[_currentIndex];
        final totalQuestions = questionsList.length;

        return Scaffold(
          // Configuration de l'AppBar
          appBar: AppBar(
            // Le titre de l'image est "Leçon : Lecon1:", mais on utilise le titre de la leçon pour être dynamique
            title: Text('Leçon : ${widget.lesson.title}'), 
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context), // Retour en arrière
            ),
            automaticallyImplyLeading: false, // Contrôlé par le bouton `close`
            backgroundColor: Colors.white, // Correspond à l'arrière-plan de l'image
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          
          // 🚨 Contenu principal de la question 
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: _buildQuestionContent(currentQuestion, totalQuestions),
          ),
          
          // 🚨 Barre du bas avec le panneau de feedback et le bouton Valider
          bottomNavigationBar: _buildBottomBar(currentQuestion), 
        );
      },
    );
  }
}